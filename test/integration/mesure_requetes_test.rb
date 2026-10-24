require "test_helper"

# Plafonds de requêtes. Ils ne décrivent pas un idéal mais l'état constaté :
# leur rôle est d'empêcher que ça empire, et de baisser à mesure qu'on
# optimise. Le tableau kanban coûte aujourd'hui une douzaine de requêtes par
# tâche — c'est la page à reprendre en premier.
class MesureRequetesTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  PLAFONDS = { "accueil" => 6, "projets" => 25, "kanban" => 160, "progression" => 35,
               "feuille de route" => 20, "matières" => 15, "équipes" => 25, "bilan" => 8,
               "étudiants" => 15 }.freeze

  setup do
    montrer_les_erreurs!
    @batch = Batch.create!(title: "Promo mesure #{SecureRandom.hex(4)}")
    ref = Referential.create!(title: "Réf", batch: @batch, active: true)
    bloc = SkillBlock.create!(referential: ref, title: "Bloc", position: 1)
    @skills = (1..6).map { |i| Skill.create!(skill_block: bloc, title: "C#{i}", position: i) }
    @projets = (1..8).map do |i|
      Project.create!(batch: @batch, name: "P#{i}", description: "d", max_booking: 4, subject: :physique)
    end
    ue = Ue.create!(batch: @batch, name: "Mécanique")
    groupe = Group.create!(ue: ue, label: "TD-01", kind: :td)

    @eleves = (1..5).map { |i| creer_eleve("5000000#{i}") }
    @team = Team.create!(name: "Équipe mesure", project: @projets.first, user: @eleves.first)
    @eleves.each { |e| e.update!(team: @team); GroupMembership.create!(user: e, group: groupe) }

    liste = @team.lists.order(:position).first
    12.times do |i|
      c = Card.create!(list: liste, name: "Tâche #{i}", description: "d",
                       time_estimate: 2, time_unit: "jour(s)")
      Assignment.create!(card: c, user: @eleves[i % 5])
      CardSkill.create!(card: c, skill: @skills[i % 6])
    end
    5.times do |i|
      Lesson.create!(batch: @batch, ue: ue, title: "TD-01 - Mécanique #{i}",
                     starts_at: (i + 1).days.ago, ends_at: (i + 1).days.ago + 2.hours)
    end
    @prof = creer_prof
    Supervision.create!(user: @prof, project: @projets.first)
  end

  test "les pages de l'étudiant restent sous leur plafond de requêtes" do
    sign_in @eleves.first
    verifier "accueil", root_path
    verifier "projets", projects_path
    verifier "kanban", team_path(@team)
    verifier "progression", team_progressions_path(@team)
    verifier "feuille de route", team_roadmap_path(@team)
    verifier "matières", matieres_path
  end

  test "les pages de l'enseignant restent sous leur plafond de requêtes" do
    sign_in @prof
    verifier "équipes", teacher_teams_path(batch_id: @batch.id)
    verifier "bilan", teacher_bilan_path
  end

  # La vue d'ensemble affiche une promotion entière : c'est la page où un N+1
  # coûterait le plus cher, une requête par étudiant.
  test "la vue d'ensemble des étudiants reste sous son plafond" do
    @prof.update!(admin: true)
    sign_in @prof
    verifier "étudiants", teacher_etudiants_path(batch_id: @batch.id)
  end

  private

  def verifier(nom, chemin)
    compte = compter(chemin)
    assert_response :success, "#{nom} devrait répondre"
    assert_operator compte, :<=, PLAFONDS.fetch(nom),
                    "#{nom} : #{compte} requêtes, plafond #{PLAFONDS.fetch(nom)}"
  end

  def compter(chemin)
    n = 0
    abonnement = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      n += 1 unless payload[:name].to_s =~ /SCHEMA|TRANSACTION/
    end
    get chemin
    ActiveSupport::Notifications.unsubscribe(abonnement)
    n
  end
end
