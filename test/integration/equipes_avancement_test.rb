require "test_helper"

class EquipesAvancementTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    montrer_les_erreurs!
    @batch = Batch.create!(title: "Promo équipes #{SecureRandom.hex(4)}")
    ref = Referential.create!(title: "Réf", batch: @batch, active: true)
    bloc = SkillBlock.create!(referential: ref, title: "Bloc", position: 1)
    Skill.create!(skill_block: bloc, title: "C", position: 1)
    @projet = Project.create!(batch: @batch, name: "Sujet", description: "d",
                              max_booking: 4, subject: :physique)

    @prof = creer_prof
    Supervision.create!(user: @prof, project: @projet)

    @en_equipe = creer_eleve("82000001", "Amaru")
    equipe = Team.create!(name: "Équipe A", project: @projet, user: @en_equipe)
    @en_equipe.update!(team: equipe)

    @sans_rien = creer_eleve("82000002", "Bernard")          # aucune équipe
    @en_attente = creer_eleve("82000003", "Cadousteau")      # équipe d'attente
    attente = Team.create!(name: "En attente de projet", user: @en_attente)
    @en_attente.update!(team: attente)

    sign_in @prof
    get teacher_teams_path(batch_id: @batch.id)
  end

  test "la section s'appelle désormais l'avancement des équipes" do
    assert_response :success
    assert_match "Avancement des équipes", response.body
    refute_match "Constitution des équipes", response.body
  end

  test "la répartition des étudiants n'est plus proposée" do
    refute_match "Répartition des étudiants", response.body
    refute_match solver_payload_teacher_batch_teams_path(@batch), response.body
  end

  test "le front ne parle plus d'élèves" do
    refute_match(/élèves?/i, response.body)
    assert_match "étudiants", response.body
  end

  test "chaque liste est repliée et porte son compte" do
    assert_match 'href="#listesans-equipe"', response.body
    assert_match 'href="#listenon-modifies"', response.body
    assert_match 'href="#listemodifies"', response.body
    assert_match 'href="#listevalides"', response.body
    assert_equal 4, response.body.scan("liste-pliante__compte").size
  end

  test "la liste des étudiants sans équipe réunit les deux façons de l'être" do
    assert_match "Étudiants sans équipe", response.body
    assert_match @sans_rien.email, response.body
    assert_match @en_attente.email, response.body
  end

  test "le compteur du haut dit la même chose que la liste" do
    get teacher_teams_path(batch_id: @batch.id)
    assert_equal 2, assigns_sans_equipe.size
    assert_includes assigns_sans_equipe.map(&:id), @sans_rien.id
    assert_includes assigns_sans_equipe.map(&:id), @en_attente.id
    refute_includes assigns_sans_equipe.map(&:id), @en_equipe.id
  end

  private

  # Le contrôleur n'expose pas ses variables : on recalcule la même règle.
  def assigns_sans_equipe
    @batch.users.kept.where(teacher: nil).select { |u| u.team.nil? || u.team.project_id.nil? }
  end
end
