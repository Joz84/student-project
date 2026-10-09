require "test_helper"

# Ce qu'un étudiant voit de sa propre assiduité. Un enseignant peut le porter
# absent des jours après le cours : sans cette page, il ne l'apprendrait jamais.
class PresencesEtudiantTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    montrer_les_erreurs!
    @batch = Batch.create!(title: "Promo présences #{SecureRandom.hex(4)}")
    @ue = Ue.create!(batch: @batch, name: "Mécanique", code: "1.3", position: 3)
    @groupe = Group.create!(ue: @ue, label: "TD-01", kind: :td)
    @prof = creer_prof
    @eleve = creer_eleve("87000001", "Teina")
    GroupMembership.create!(user: @eleve, group: @groupe)

    @passee = seance(4.days.ago)
    @avant_hier = seance(2.days.ago)
    @hier = seance(1.day.ago)
    sign_in @eleve
  end

  test "une absence saisie après le cours lui est visible" do
    @passee.attendances.create!(user: @eleve, status: :absent, declared_by: :teacher)

    get matieres_path
    assert_response :success
    assert_match "Le détail de mes présences", response.body
    assert_match "Absent non justifié", response.body
    assert_match "votre enseignant", response.body
    assert_match "1 absence non justifiée", response.body
  end

  test "le compte par matière distingue les quatre états" do
    @passee.attendances.create!(user: @eleve, status: :present, declared_by: :student)
    @avant_hier.attendances.create!(user: @eleve, status: :excused, declared_by: :teacher)
    @hier.attendances.create!(user: @eleve, status: :retard, declared_by: :teacher)

    get matieres_path
    assert_match "sur 3 séances renseignées", response.body
    assert_match "1 justifiée", response.body
    assert_match "1 retard", response.body
    refute_match "absence non justifiée", response.body
  end

  test "il voit qui a saisi quoi" do
    @passee.attendances.create!(user: @eleve, status: :present, declared_by: :student)
    @hier.attendances.create!(user: @eleve, status: :present, declared_by: :teacher)

    get matieres_path
    assert_match "vous-même", response.body
    assert_match "votre enseignant", response.body
  end

  test "il est invité à signaler une erreur plutôt qu'à la subir" do
    @passee.attendances.create!(user: @eleve, status: :absent, declared_by: :teacher)
    get matieres_path
    assert_match "Dites-le à l'enseignant concerné", response.body
  end

  test "sans aucun pointage, le relevé ne s'affiche pas" do
    get matieres_path
    refute_match "Le détail de mes présences", response.body
    refute_match "Mes présences", response.body
  end

  test "un pointage sur une matière hors de ses groupes figure quand même" do
    autre = Ue.create!(batch: @batch, name: "Chimie", code: "1.9", position: 9)
    rattrapage = Lesson.create!(batch: @batch, ue: autre, teacher: @prof,
                                title: "TP-02 - Chimie", starts_at: 3.days.ago,
                                ends_at: 3.days.ago + 2.hours)
    rattrapage.attendances.create!(user: @eleve, status: :present, declared_by: :teacher)

    get matieres_path
    assert_match "TP-02 - Chimie", response.body, "un rattrapage compte aussi"
  end

  private

  def seance(debut)
    l = Lesson.create!(batch: @batch, ue: @ue, teacher: @prof, title: "TD-01 - Mécanique",
                       starts_at: debut, ends_at: debut + 2.hours)
    LessonGroup.create!(lesson: l, group: @groupe)
    l
  end
end
