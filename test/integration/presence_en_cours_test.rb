require "test_helper"

# Ce que l'étudiant voit sur l'accueil pendant que la séance a lieu. Qu'il se
# soit signalé lui-même ou que l'enseignant l'ait pointé, la ligne doit dire
# la même chose — sans quoi il se croit non compté et redemande.
class PresenceEnCoursTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    montrer_les_erreurs!
    @batch = Batch.create!(title: "Promo en cours #{SecureRandom.hex(4)}")
    @ue = Ue.create!(batch: @batch, name: "Mécanique", code: "1.3", position: 3)
    @groupe = Group.create!(ue: @ue, label: "TD-01", kind: :td)
    @prof = creer_prof
    @eleve = creer_eleve("88000001", "Teina")
    GroupMembership.create!(user: @eleve, group: @groupe)

    @en_cours = Lesson.create!(batch: @batch, ue: @ue, teacher: @prof,
                               title: "TD-01 - Mécanique", starts_at: 20.minutes.ago,
                               ends_at: 1.hour.from_now)
    LessonGroup.create!(lesson: @en_cours, group: @groupe)
    @en_cours.ouvrir_pointage!
  end

  test "pointé par son enseignant, il le voit pendant la séance" do
    @en_cours.attendances.create!(user: @eleve, status: :present, declared_by: :teacher)

    sign_in @eleve
    get root_path
    assert_response :success
    assert_match @en_cours.title, response.body
    assert_match "Présence enregistrée", response.body
    assert_match "par votre enseignant", response.body
    refute_match "Je suis présent", response.body, "on ne lui redemande pas de se signaler"
  end

  test "signalé par lui-même, il voit la même chose sans la mention" do
    @en_cours.attendances.create!(user: @eleve, status: :present, declared_by: :student)

    sign_in @eleve
    get root_path
    assert_match "Présence enregistrée", response.body
    refute_match "par votre enseignant", response.body
  end

  test "sans pointage, le bouton reste proposé" do
    sign_in @eleve
    get root_path
    assert_match "Je suis présent", response.body
    refute_match "Présence enregistrée", response.body
  end

  test "la séance disparaît de l'accueil une fois terminée" do
    @en_cours.attendances.create!(user: @eleve, status: :present, declared_by: :teacher)
    @en_cours.update!(starts_at: 3.hours.ago, ends_at: 1.hour.ago)

    sign_in @eleve
    get root_path
    refute_match @en_cours.title, response.body
  end

  test "« Mes matières » ne récapitule pas ses présences" do
    @en_cours.attendances.create!(user: @eleve, status: :absent, declared_by: :teacher)
    sign_in @eleve
    get matieres_path
    assert_response :success
    refute_match "Le détail de mes présences", response.body
    refute_match "presence-matiere", response.body
  end
end
