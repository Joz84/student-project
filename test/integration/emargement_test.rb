require "test_helper"

class EmargementTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    # Sans cela l'application rend ses propres pages d'erreur et masque la cause.
    Rails.application.env_config["action_dispatch.show_exceptions"] = :none
    @batch = Batch.create!(title: "Promo test #{SecureRandom.hex(4)}")
    @ue    = Ue.create!(batch: @batch, name: "UE de test")
    @groupe = Group.create!(ue: @ue, label: "TD-01", kind: :td)

    @eleve = creer_eleve("11111111")
    GroupMembership.create!(user: @eleve, group: @groupe)
    @absent = creer_eleve("22222222")
    GroupMembership.create!(user: @absent, group: @groupe)
    @sans_groupe = creer_eleve("33333333")   # les « sans TP » : doivent voir les CM

    @prof = User.create!(email: "prof-#{SecureRandom.hex(4)}@upf.pf", first_name: "Prof",
                         last_name: "Test", student_number: "12345678", teacher: true,
                         batch: @batch, password: "motdepasse")

    @td = Lesson.create!(batch: @batch, ue: @ue, teacher: @prof, ade_uid: SecureRandom.hex(8),
                         title: "TD-01 - UE de test", category: :td, room: "G3-2",
                         starts_at: 30.minutes.ago, ends_at: 1.hour.from_now)
    LessonGroup.create!(lesson: @td, group: @groupe)

    @cm = Lesson.create!(batch: @batch, ue: @ue, teacher: @prof, ade_uid: SecureRandom.hex(8),
                         title: "CM - UE de test", category: :cm,
                         starts_at: 2.hours.from_now, ends_at: 3.hours.from_now)
  end

  test "l'étudiant voit ses cours et le cours en cours" do
    sign_in @eleve
    get root_path
    assert_response :success
    assert_match "TD-01 - UE de test", response.body
    assert_match "Appel non ouvert", response.body
  end

  test "un étudiant sans groupe voit quand même les CM de sa promotion" do
    assert @cm.concerne?(@sans_groupe), "le CM doit concerner un étudiant sans groupe"
    refute @td.concerne?(@sans_groupe), "le TD ne doit pas le concerner"
    sign_in @sans_groupe
    get root_path
    assert_match "CM - UE de test", response.body
  end

  test "pointage refusé tant que l'enseignant n'a pas ouvert l'appel" do
    sign_in @eleve
    post lesson_attendance_path(@td), params: { code: "0000" }
    assert_equal 0, @td.attendances.count
    assert_match(/n'est pas ouvert/, flash[:alert])
  end

  test "pointage refusé avec un mauvais code" do
    @td.ouvrir_pointage!
    sign_in @eleve
    post lesson_attendance_path(@td), params: { code: "0000" }
    assert_equal 0, @td.attendances.where(status: :present).count
    assert_match(/Code incorrect/, flash[:alert])
  end

  test "pointage accepté avec le bon code, puis refusé une fois figé" do
    @td.ouvrir_pointage!
    sign_in @eleve
    post lesson_attendance_path(@td), params: { code: @td.attendance_code }
    assert_equal 1, @td.attendances.where(status: :present).count
    assert @td.attendances.first.by_student?

    @td.verrouiller!
    sign_in @absent
    post lesson_attendance_path(@td), params: { code: @td.attendance_code }
    assert_equal 1, @td.reload.presents_count, "le gel doit empêcher tout nouveau pointage"
  end

  test "la feuille d'appel affiche les attendus et le compte" do
    @td.ouvrir_pointage!
    Attendance.create!(lesson: @td, user: @eleve, status: :present, declared_by: :student)
    sign_in @prof
    get teacher_lesson_path(@td)
    assert_response :success
    assert_match @td.attendance_code, response.body
    assert_match "sur 2 attendus", response.body
    get liste_teacher_lesson_path(@td)
    assert_response :success
  end

  test "l'enseignant peut pointer un étudiant et valider l'appel" do
    @td.ouvrir_pointage!
    sign_in @prof
    patch teacher_lesson_attendance_path(@td, @eleve), params: { status: :present }
    assert @td.attendances.find_by(user: @eleve).statut_present?

    post valider_teacher_lesson_path(@td)
    @td.reload
    assert @td.valide?
    assert_equal 1, @td.presents_count
    assert @td.attendances.find_by(user: @absent).statut_absent?, "les non pointés sont portés absents"
  end

  test "l'enseignant peut pointer un étudiant de la promo hors de sa liste" do
    rattrapage = creer_eleve("44444444")   # aucun groupe : pas attendu au TD
    refute @td.concerne?(rattrapage)
    assert_includes @td.eleves_hors_liste, rattrapage

    sign_in @prof
    patch teacher_lesson_attendance_path(@td, rattrapage), params: { status: :present }
    assert @td.attendances.find_by(user: rattrapage).statut_present?

    get teacher_lesson_path(@td)
    assert_match "Hors liste", response.body
    assert_match rattrapage.last_name, response.body
  end

  test "l'enseignant saisit un étudiant absent de toutes les listes, sans validation" do
    sign_in @prof
    assert_difference -> { @td.attendances.count }, 1 do
      post teacher_lesson_attendances_path(@td),
           params: { guest_first_name: "Moana", guest_last_name: "Tera", guest_student_number: "pas-un-numero" }
    end
    invite = @td.attendances.invites.last
    assert invite.statut_present?
    assert_equal "Moana Tera", invite.nom_complet
    assert_equal "pas-un-numero", invite.numero, "aucun format n'est imposé"

    # Une ligne entièrement vide n'a pas de sens et n'est pas créée.
    assert_no_difference -> { @td.attendances.count } do
      post teacher_lesson_attendances_path(@td), params: { guest_first_name: " " }
    end

    assert_difference -> { @td.attendances.count }, -1 do
      delete teacher_lesson_attendance_path(@td, invite)
    end
  end

  test "un invité compte dans les présents et survit à la validation" do
    sign_in @prof
    post teacher_lesson_attendances_path(@td), params: { guest_last_name: "Visiteur" }
    post valider_teacher_lesson_path(@td)
    @td.reload
    assert @td.valide?
    assert_equal 1, @td.presents_count, "l'invité est compté présent"
    assert_equal 2, @td.attendances.where(status: :absent).count, "les attendus non pointés sont absents"
  end

  test "un étudiant ne peut pas ouvrir la feuille d'appel" do
    sign_in @eleve
    get teacher_lesson_path(@td)
    assert_redirected_to root_path
  end

  private

  def creer_eleve(numero)
    User.create!(email: "eleve-#{SecureRandom.hex(4)}@etudiant.upf.pf",
                 first_name: "Test", last_name: "Eleve#{numero}",
                 student_number: numero, batch: @batch, password: "motdepasse")
  end
end
