require "test_helper"

# L'enseignant qui ajoute quelqu'un choisit la portée de sa saisie : cette
# séance seulement, ou toute la matière.
class PorteeInscriptionTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    montrer_les_erreurs!
    @batch = Batch.create!(title: "Promo portée #{SecureRandom.hex(4)}")
    @ue = Ue.create!(batch: @batch, name: "Mécanique du solide", code: "1.3", position: 3)
    @groupe = Group.create!(ue: @ue, label: "TD-01", kind: :td)

    @inscrit = creer_eleve("81000001", "Amaru")
    GroupMembership.create!(user: @inscrit, group: @groupe)
    @promo = creer_eleve("81000002", "Hauata")   # même promo, autre groupe

    @prof = creer_prof
    @aujourdhui = seance(30.minutes.ago)
    @demain = seance(1.day.from_now)
    @aujourdhui.ouvrir_pointage!
    sign_in @prof
  end

  # --- saisie libre sur la feuille d'appel ---

  test "une saisie libre ponctuelle ne vaut que pour la séance" do
    assert_no_difference -> { UeGuest.count } do
      post teacher_lesson_attendances_path(@aujourdhui), params: {
        guest_first_name: "Vaiana", guest_last_name: "Tepuhiarii",
        guest_student_number: "20260999", portee: "seance"
      }
    end
    assert_equal 1, @aujourdhui.attendances.count
    assert_equal 0, @demain.invites_permanents.count
  end

  test "une saisie libre sur toute la matière revient à chaque séance" do
    assert_difference -> { UeGuest.count }, 1 do
      post teacher_lesson_attendances_path(@aujourdhui), params: {
        guest_first_name: "Vaiana", guest_last_name: "Tepuhiarii",
        guest_student_number: "20260999", portee: "matiere"
      }
    end
    assert_match "Inscrit sur toute la matière", flash[:notice]

    invite = UeGuest.last
    assert invite.permanent?
    assert_equal @ue, invite.ue
    assert_equal [invite.id], @demain.invites_permanents.ids

    get teacher_lesson_path(@demain)
    assert_response :success
    assert_match "Inscrits sur la matière", response.body
    assert_match "Vaiana Tepuhiarii", response.body
  end

  test "la même personne ajoutée deux fois ne fait pas deux lignes" do
    2.times do
      post teacher_lesson_attendances_path(@aujourdhui), params: {
        guest_first_name: "Vaiana", guest_last_name: "Tepuhiarii",
        guest_student_number: "20260999", portee: "matiere"
      }
    end
    assert_equal 1, UeGuest.where(ue: @ue).count
  end

  # --- pointage d'un étudiant de la promotion ---

  test "un étudiant de la promo pointé pour la séance n'est pas attendu ensuite" do
    patch teacher_lesson_attendance_path(@aujourdhui, @promo),
          params: { status: "present", portee: "seance" }
    assert @aujourdhui.attendances.find_by(user: @promo).statut_present?
    refute @demain.eleves_attendus.exists?(@promo.id)
  end

  test "un étudiant de la promo inscrit sur la matière est attendu ensuite" do
    assert_difference -> { UeGuest.count }, 1 do
      patch teacher_lesson_attendance_path(@aujourdhui, @promo),
            params: { status: "present", portee: "matiere" }
    end
    invite = UeGuest.last
    assert_equal @promo, invite.user
    assert invite.permanent?

    assert @demain.eleves_attendus.exists?(@promo.id), "il figure désormais sur la liste"
    assert @demain.concerne?(@promo.reload), "et la séance apparaît dans son agenda"
  end

  test "l'inscrire deux fois ne crée pas de doublon" do
    2.times do
      patch teacher_lesson_attendance_path(@aujourdhui, @promo),
            params: { status: "present", portee: "matiere" }
    end
    assert_equal 1, UeGuest.where(ue: @ue, user: @promo).count
  end

  test "il n'est compté qu'une fois s'il rejoint aussi un groupe" do
    patch teacher_lesson_attendance_path(@aujourdhui, @promo),
          params: { status: "present", portee: "matiere" }
    GroupMembership.create!(user: @promo, group: @groupe)
    assert_equal 1, @demain.eleves_attendus.where(id: @promo.id).count
  end

  # --- formulaire du relevé ---

  test "le relevé ajoute par défaut sur toute la matière" do
    post eleve_teacher_bilan_path, params: { ue_id: @ue.id,
      guest_last_name: "Faatau", guest_first_name: "Moana" }
    invite = UeGuest.last
    assert invite.permanent?
    assert_match "attendu à chaque séance", flash[:notice]
    assert_equal [invite.id], @demain.invites_permanents.ids
  end

  test "le relevé peut n'ajouter que pour lui-même" do
    post eleve_teacher_bilan_path, params: { ue_id: @ue.id,
      guest_last_name: "Faatau", guest_first_name: "Moana", portee: "releve" }
    invite = UeGuest.last
    refute invite.permanent?
    assert_match "ne figure que dans ce relevé", flash[:notice]
    assert_equal 0, @demain.invites_permanents.count

    # Il reste visible dans la grille, c'est sa raison d'être.
    sheet = AttendanceSheet.new(teacher: @prof, ue: @ue)
    assert_includes sheet.invites.map(&:libelle), "Moana Faatau"
  end

  # --- ce que l'étudiant ajouté voit de son côté ---

  test "l'étudiant pointé en rattrapage voit la séance et son état" do
    patch teacher_lesson_attendance_path(@aujourdhui, @promo),
          params: { status: "present", portee: "seance" }
    sign_out @prof

    refute @aujourdhui.concerne?(@promo), "ce n'est pas une séance de ses groupes"

    sign_in @promo
    get root_path
    assert_response :success
    assert_match @aujourdhui.title, response.body, "la séance doit apparaître chez lui"
    assert_match "Présence enregistrée", response.body
    assert_match "par votre enseignant", response.body
    assert_match "rattrapage", response.body
  end

  test "une séance où il n'est ni attendu ni pointé reste invisible" do
    sign_out @prof
    sign_in @promo
    get root_path
    refute_match @demain.title, response.body
  end

  test "un pointage d'absence lui montre aussi la séance" do
    patch teacher_lesson_attendance_path(@aujourdhui, @promo),
          params: { status: "excused", portee: "seance" }
    sign_out @prof

    sign_in @promo
    get root_path
    assert_match @aujourdhui.title, response.body
    refute_match "Présence enregistrée", response.body
  end

  test "inscrit sur toute la matière, il voit les séances à venir" do
    patch teacher_lesson_attendance_path(@aujourdhui, @promo),
          params: { status: "present", portee: "matiere" }
    sign_out @prof

    sign_in @promo
    get root_path
    assert_match @demain.title, response.body, "les séances suivantes aussi"
    refute_match "rattrapage", response.body, "il fait désormais partie de la liste"
  end

  test "l'étudiant de la liste reste maître de son propre pointage" do
    patch teacher_lesson_attendance_path(@aujourdhui, @promo),
          params: { status: "present", portee: "matiere" }
    sign_out @prof

    sign_in @promo
    post lesson_attendance_path(@aujourdhui), params: { code: @aujourdhui.attendance_code }
    assert_equal 1, @aujourdhui.attendances.where(user: @promo).count
  end

  private

  def seance(debut)
    l = Lesson.create!(batch: @batch, ue: @ue, teacher: @prof, title: "TD-01 - Mécanique du solide",
                       starts_at: debut, ends_at: debut + 2.hours)
    LessonGroup.create!(lesson: l, group: @groupe)
    l
  end
end
