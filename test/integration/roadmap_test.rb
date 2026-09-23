require "test_helper"

class RoadmapTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Rails.application.env_config["action_dispatch.show_exceptions"] = :none
    @batch = Batch.create!(title: "Promo roadmap #{SecureRandom.hex(4)}")
    ref = Referential.create!(title: "Référentiel test", batch: @batch, active: true)
    bloc = SkillBlock.create!(referential: ref, title: "Bloc", position: 1)
    Skill.create!(skill_block: bloc, title: "Compétence", position: 1)
    @projet = Project.create!(batch: @batch, name: "Sujet", description: "x",
                              max_booking: 4, subject: :physique)
    @eleve = creer_eleve("70000001")
    @team = Team.create!(name: "Équipe #{SecureRandom.hex(4)}", project: @projet, user: @eleve)
    @eleve.update!(team: @team)
    @autre = creer_eleve("70000002")   # membre d'une autre équipe
    @listes = @team.lists.order(:position)
    @afaire, @finies = @listes.first, @listes.last
  end

  test "l'onglet mène à la feuille de route" do
    sign_in @eleve
    get team_path(@team)
    assert_response :success
    assert_match team_roadmap_path(@team), response.body

    get team_roadmap_path(@team)
    assert_response :success
    assert_match "Feuille de route", response.body
  end

  test "les trois onglets portent la barre latérale et se signalent l'un l'autre" do
    sign_in @eleve
    { team_path(@team) => "Tableau de bord",
      team_roadmap_path(@team) => "Feuille de route",
      team_progressions_path(@team) => "Progression" }.each do |chemin, _|
      get chemin
      assert_response :success, "#{chemin} doit répondre"
      assert_match "onglets-equipe", response.body, "#{chemin} sans onglets"
      assert_match "col-md-3 bg-primary", response.body, "#{chemin} sans barre latérale"
      assert_equal 1, response.body.scan("onglet--actif").size, "#{chemin} : un seul onglet actif"
    end
  end

  test "créer, modifier, réordonner et supprimer un jalon" do
    sign_in @eleve
    post team_milestones_path(@team), params: { milestone: { name: "Prototype", due_on: "2026-12-01" } }
    post team_milestones_path(@team), params: { milestone: { name: "Livraison" } }
    assert_equal %w[Prototype Livraison], @team.milestones.ordonnes.pluck(:name)

    second = @team.milestones.ordonnes.last
    patch monter_team_milestone_path(@team, second)
    assert_equal %w[Livraison Prototype], @team.milestones.ordonnes.pluck(:name)

    patch team_milestone_path(@team, second), params: { milestone: { name: "Livraison finale" } }
    assert_equal "Livraison finale", second.reload.name

    assert_difference -> { Milestone.count }, -1 do
      delete team_milestone_path(@team, second)
    end
  end

  test "une échéance antérieure au début est refusée" do
    sign_in @eleve
    assert_no_difference -> { Milestone.count } do
      post team_milestones_path(@team),
           params: { milestone: { name: "Incohérent", starts_on: "2026-12-01", due_on: "2026-11-01" } }
    end
    assert_match(/date de début/, flash[:alert])
  end

  test "rattacher une tâche à un jalon, la voir des deux côtés" do
    jalon = @team.milestones.create!(name: "Prototype")
    tache = carte(@afaire, "Souder la carte")
    sign_in @eleve

    patch card_path(tache), params: { card: { milestone_id: jalon.id } }
    assert_equal jalon.id, tache.reload.milestone_id

    # Sur la feuille de route
    get team_roadmap_path(@team)
    assert_match "Souder la carte", response.body
    # Sur la carte du tableau
    get team_path(@team)
    assert_match "kanban-card__jalon", response.body
    assert_match "Prototype", response.body
  end

  test "l'avancement se déduit des tâches terminées" do
    jalon = @team.milestones.create!(name: "Prototype")
    carte(@afaire, "A").update!(milestone: jalon)
    carte(@finies, "B").update!(milestone: jalon)
    assert_equal 50, jalon.reload.avancement

    carte(@finies, "C").update!(milestone: jalon)
    assert_equal 67, jalon.reload.avancement
    assert_nil @team.milestones.create!(name: "Vide").avancement
  end

  test "supprimer un jalon laisse ses tâches au tableau" do
    jalon = @team.milestones.create!(name: "Prototype")
    tache = carte(@afaire, "Souder")
    tache.update!(milestone: jalon)
    sign_in @eleve
    delete team_milestone_path(@team, jalon)
    assert Card.exists?(tache.id), "la tâche survit à son jalon"
    assert_nil tache.reload.milestone_id
  end

  test "un jalon dépassé et inachevé est signalé en retard" do
    jalon = @team.milestones.create!(name: "Prototype", due_on: 3.days.ago.to_date)
    tache = carte(@afaire, "A")
    tache.update!(milestone: jalon)
    assert jalon.reload.en_retard?

    tache.update!(list: @finies)
    refute jalon.reload.en_retard?, "un jalon achevé n'est pas en retard"
  end

  test "un étranger à l'équipe ne peut pas toucher à ses jalons" do
    jalon = @team.milestones.create!(name: "Prototype")
    sign_in @autre
    patch team_milestone_path(@team, jalon), params: { milestone: { name: "Pirate" } }
    assert_redirected_to root_path
    assert_equal "Prototype", jalon.reload.name
  end

  private

  def creer_eleve(numero)
    User.create!(email: "r-#{SecureRandom.hex(4)}@etudiant.upf.pf", first_name: "T",
                 last_name: "Eleve#{numero}", student_number: numero, batch: @batch,
                 password: "motdepasse")
  end

  def carte(liste, nom)
    Card.create!(list: liste, name: nom, description: "d", time_estimate: 1, time_unit: "jour(s)")
  end
end
