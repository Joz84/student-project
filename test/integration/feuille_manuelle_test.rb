require "test_helper"

class FeuilleManuelleTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    montrer_les_erreurs!
    @batch = Batch.create!(title: "Promo manuelle #{SecureRandom.hex(4)}")
    @ue = Ue.create!(batch: @batch, name: "Calcul fonctionnel", code: "1.2", position: 1)
    @td1 = Group.create!(ue: @ue, label: "TD-01", kind: :td)
    @td2 = Group.create!(ue: @ue, label: "TD-02", kind: :td)
    @autre_ue = Ue.create!(batch: @batch, name: "Anglais", code: "2.8", position: 20)

    @eleve = creer_eleve("70000011", "Amaru")
    GroupMembership.create!(user: @eleve, group: @td1)
    @hors = creer_eleve("70000012", "Hauata")

    @prof = creer_prof
    # Une séance venue d'ADE, pour que la promotion figure dans ses choix.
    Lesson.create!(batch: @batch, ue: @ue, teacher: @prof, title: "TD-01 - Calcul fonctionnel",
                   starts_at: 3.days.ago, ends_at: 3.days.ago + 2.hours)
  end

  test "le formulaire propose la maquette, codes en tête" do
    sign_in @prof
    get new_teacher_lesson_path
    assert_response :success
    assert_match "1.2 — Calcul fonctionnel", response.body
    assert_match "2.8 — Anglais", response.body
    assert_match "TD-01", response.body
  end

  test "créer une feuille sans groupe : elle n'attend personne" do
    sign_in @prof
    assert_difference -> { Lesson.count }, 1 do
      post teacher_lessons_path, params: {
        lesson: { ue_id: @ue.id, room: "C2-2", category: "autre" },
        jour: Date.current.to_s, debut: "08:00", fin: "10:00"
      }
    end
    seance = Lesson.order(:created_at).last
    assert_redirected_to teacher_lesson_path(seance)

    assert seance.manuelle?
    assert_equal @prof, seance.teacher
    assert_equal @batch, seance.batch
    assert_equal "Calcul fonctionnel", seance.title
    assert_equal 0, seance.eleves_attendus.count, "sans groupe, la feuille part vide"
    refute seance.concerne?(@eleve), "elle n'apparaît pas dans l'agenda des étudiants"
    assert_includes seance.eleves_hors_liste.pluck(:id), @eleve.id
  end

  test "créer une feuille avec des groupes : les étudiants sont pré-remplis" do
    sign_in @prof
    post teacher_lessons_path, params: {
      lesson: { ue_id: @ue.id, category: "td" },
      jour: Date.current.to_s, debut: "13:00", fin: "15:00",
      group_ids: ["", @td1.id.to_s]
    }
    seance = Lesson.order(:created_at).last
    assert_equal "TD-01 - Calcul fonctionnel", seance.title
    assert_equal [@eleve.id], seance.eleves_attendus.pluck(:id)
    assert seance.concerne?(@eleve.reload)
  end

  test "un groupe d'une autre UE est ignoré" do
    autre_groupe = Group.create!(ue: @autre_ue, label: "TD-09", kind: :td)
    sign_in @prof
    post teacher_lessons_path, params: {
      lesson: { ue_id: @ue.id, category: "td" },
      jour: Date.current.to_s, debut: "13:00", fin: "15:00",
      group_ids: [autre_groupe.id.to_s]
    }
    seance = Lesson.order(:created_at).last
    assert_empty seance.groups, "on ne rattache pas un groupe étranger au cours choisi"
  end

  test "une fin antérieure au début est refusée" do
    sign_in @prof
    assert_no_difference -> { Lesson.count } do
      post teacher_lessons_path, params: {
        lesson: { ue_id: @ue.id, category: "autre" },
        jour: Date.current.to_s, debut: "10:00", fin: "08:00"
      }
    end
    assert_equal 422, response.status
    assert_match "doit être après", response.body
  end

  test "sans cours choisi, rien n'est créé" do
    sign_in @prof
    assert_no_difference -> { Lesson.count } do
      post teacher_lessons_path, params: {
        lesson: { ue_id: "", category: "autre" },
        jour: Date.current.to_s, debut: "08:00", fin: "10:00"
      }
    end
    assert_equal 422, response.status
  end

  test "l'enseignant pointe un étudiant hors liste sur sa feuille" do
    sign_in @prof
    post teacher_lessons_path, params: {
      lesson: { ue_id: @ue.id, category: "autre" },
      jour: Date.current.to_s, debut: "08:00", fin: "10:00"
    }
    seance = Lesson.order(:created_at).last

    patch teacher_lesson_attendance_path(seance, @hors), params: { status: "present" }
    assert_equal 1, seance.attendances.count
    assert seance.attendances.first.statut_present?

    post teacher_lesson_attendances_path(seance), params: {
      guest_first_name: "Vaiana", guest_last_name: "Tepuhiarii", guest_student_number: "20260999"
    }
    assert_equal 2, seance.attendances.count
    assert_equal 2, seance.reload.presents_count
  end

  test "un étudiant ne crée pas de feuille d'appel" do
    sign_in @eleve
    get new_teacher_lesson_path
    assert_redirected_to root_path
    assert_no_difference -> { Lesson.count } do
      post teacher_lessons_path, params: {
        lesson: { ue_id: @ue.id, category: "autre" },
        jour: Date.current.to_s, debut: "08:00", fin: "10:00"
      }
    end
  end

  test "la feuille manuelle figure au bilan de l'enseignant" do
    sign_in @prof
    post teacher_lessons_path, params: {
      lesson: { ue_id: @ue.id, category: "autre" },
      jour: 1.hour.ago.to_date.to_s, debut: (1.hour.ago).strftime("%H:%M"), fin: Time.current.strftime("%H:%M"),
      group_ids: [@td1.id.to_s]
    }
    seance = Lesson.order(:created_at).last
    get teacher_bilan_path(ue_id: @ue.id)
    assert_response :success
    assert_match seance.starts_at.strftime("%d/%m"), response.body
  end
end
