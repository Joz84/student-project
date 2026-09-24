require "test_helper"

# Qui atteint quoi. Ces tests remplacent les squelettes du générateur : ils
# parcourent les pages réellement servies et vérifient les portes.
class AccesTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    montrer_les_erreurs!
    @batch = Batch.create!(title: "Promo accès #{SecureRandom.hex(4)}")
    ref = Referential.create!(title: "Réf", batch: @batch, active: true)
    bloc = SkillBlock.create!(referential: ref, title: "Bloc", position: 1)
    Skill.create!(skill_block: bloc, title: "Compétence", position: 1)

    @projet = Project.create!(batch: @batch, name: "Sujet", description: "d",
                              max_booking: 4, subject: :physique)
    @ue = Ue.create!(batch: @batch, name: "Mécanique")
    @groupe = Group.create!(ue: @ue, label: "TD-01", kind: :td)

    @eleve = creer_eleve("30000001")
    @team = Team.create!(name: "Équipe #{SecureRandom.hex(4)}", project: @projet, user: @eleve)
    @eleve.update!(team: @team)
    GroupMembership.create!(user: @eleve, group: @groupe)

    @etranger = creer_eleve("30000002")
    @autre_team = Team.create!(name: "Autre #{SecureRandom.hex(4)}", project: @projet, user: @etranger)
    @etranger.update!(team: @autre_team)

    @prof = creer_prof
    Supervision.create!(user: @prof, project: @projet)

    @seance = Lesson.create!(batch: @batch, ue: @ue, teacher: @prof, title: "TD-01 - Mécanique",
                             starts_at: 30.minutes.ago, ends_at: 1.hour.from_now)
    LessonGroup.create!(lesson: @seance, group: @groupe)
  end

  test "un visiteur non connecté est renvoyé vers la connexion" do
    [root_path, projects_path, matieres_path, team_path(@team), teacher_teams_path].each do |chemin|
      get chemin
      assert_redirected_to new_user_session_path, "#{chemin} doit exiger une connexion"
    end
  end

  test "l'étudiant atteint ses propres pages" do
    sign_in @eleve
    [root_path, legal_path, projects_path, matieres_path,
     team_path(@team), team_roadmap_path(@team), team_progressions_path(@team)].each do |chemin|
      get chemin
      assert_response :success, "#{chemin} devrait répondre"
    end
  end

  test "l'étudiant ne voit que les projets auxquels il a droit" do
    autre_promo = Batch.create!(title: "Ailleurs #{SecureRandom.hex(4)}")
    interdit = Project.create!(batch: autre_promo, name: "Hors promo", description: "d",
                               max_booking: 4, subject: :chimie)
    sign_in @eleve
    get projects_path
    assert_response :success
    assert_match @projet.name, response.body
    refute_match interdit.name, response.body
  end

  test "l'étudiant n'entre pas chez une autre équipe" do
    sign_in @eleve
    [team_path(@autre_team), team_roadmap_path(@autre_team), team_progressions_path(@autre_team)].each do |chemin|
      get chemin
      assert_redirected_to root_path, "#{chemin} devrait être refusé"
    end
  end

  test "l'étudiant n'atteint aucune page enseignante" do
    sign_in @eleve
    get teacher_teams_path
    assert_redirected_to root_path
    get teacher_bilan_path
    assert_redirected_to root_path
    get teacher_lesson_path(@seance)
    assert_redirected_to root_path
    get teacher_team_path(@team)
    assert_redirected_to root_path
  end

  # Régression : la page enseignante des équipes n'exigeait aucune autorisation,
  # sa seule protection tenant à une promotion vide. Un ?batch_id= dans
  # l'adresse suffisait à afficher la promo entière, adresses comprises.
  test "un étudiant n'ouvre pas la page des équipes, même en forçant la promo" do
    sign_in @eleve
    get teacher_teams_path(batch_id: @batch.id)
    assert_redirected_to root_path
    follow_redirect!
    refute_match @etranger.email, response.body
  end

  test "l'étudiant ne commande pas la feuille d'appel" do
    @seance.ouvrir_pointage!
    sign_in @eleve
    [tous_presents_teacher_lesson_path(@seance), valider_teacher_lesson_path(@seance),
     verrouiller_teacher_lesson_path(@seance)].each do |chemin|
      post chemin
      assert_redirected_to root_path, "#{chemin} devrait être refusé"
    end
    assert_equal 0, @seance.attendances.count
    refute @seance.reload.valide?
  end

  test "l'enseignant atteint ses pages" do
    sign_in @prof
    [teacher_teams_path, teacher_team_path(@team), teacher_bilan_path,
     teacher_lesson_path(@seance)].each do |chemin|
      get chemin
      assert_response :success, "#{chemin} devrait répondre"
    end
  end

  test "l'enseignant sans supervision voit une page, pas une erreur" do
    orphelin = creer_prof("Sansprojet")
    sign_in orphelin
    get teacher_teams_path
    assert_response :success
    assert_match "aucun projet", response.body
  end

  test "la page d'accueil de l'enseignant n'est pas celle de l'étudiant" do
    sign_in @prof
    get project_router_path
    assert_redirected_to teacher_teams_path
  end
end
