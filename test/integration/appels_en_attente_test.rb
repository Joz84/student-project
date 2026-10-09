require "test_helper"

# Un appel ouvert pendant le cours puis jamais validé. Tant qu'il reste en
# plan, les étudiants qui ne se sont pas signalés n'ont aucune ligne — ni
# présents ni absents — et personne ne s'en aperçoit.
class AppelsEnAttenteTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    montrer_les_erreurs!
    @batch = Batch.create!(title: "Promo attente #{SecureRandom.hex(4)}")
    @ue = Ue.create!(batch: @batch, name: "Mécanique", code: "1.3", position: 3)
    @groupe = Group.create!(ue: @ue, label: "TD-01", kind: :td)
    @prof = creer_prof
    @autre = creer_prof("Adam")
    @eleve = creer_eleve("89000001", "Teina")
    GroupMembership.create!(user: @eleve, group: @groupe)

    @oubliee = seance(@prof, 3.days.ago)
    @oubliee.ouvrir_pointage!

    @validee = seance(@prof, 2.days.ago)
    @validee.ouvrir_pointage!
    @validee.valider!

    @jamais_ouverte = seance(@prof, 4.days.ago)
    @a_venir = seance(@prof, 2.days.from_now)
  end

  test "l'appel oublié reste sur l'accueil, en tête" do
    sign_in @prof
    get root_path
    assert_response :success

    assert_match @oubliee.title, response.body
    assert_match "appel non validé", response.body
    assert_match "seance--attente", response.body
    assert_match "Valider l'appel", response.body.gsub("&#39;", "'")

    # Il précède les séances à venir : c'est l'action en retard.
    assert_operator response.body.index(@oubliee.title), :<,
                    response.body.index(@a_venir.title)
  end

  test "une séance validée ou jamais ouverte n'y figure pas" do
    sign_in @prof
    get root_path
    refute_match @validee.title, response.body
    refute_match @jamais_ouverte.title, response.body
  end

  test "il disparaît dès qu'on le valide" do
    sign_in @prof
    post valider_teacher_lesson_path(@oubliee)
    get root_path
    refute_match @oubliee.title, response.body
    refute_match "seance--attente", response.body
  end

  test "chacun ne voit que les siens" do
    sien = seance(@autre, 3.days.ago)
    sien.ouvrir_pointage!

    sign_in @prof
    get root_path
    refute_match sien.title, response.body
  end

  test "l'administrateur les voit tous quand il regarde toute la promotion" do
    sien = seance(@autre, 3.days.ago)
    sien.ouvrir_pointage!
    admin = creer_prof("Serafini")
    admin.update!(admin: true)

    sign_in admin
    get root_path
    assert_match sien.title, response.body, "ceux des collègues aussi"

    get root_path(cours: "miens")
    refute_match sien.title, response.body
  end

  test "un étudiant ne voit pas cette alerte" do
    @oubliee.attendances.create!(user: @eleve, status: :present, declared_by: :student)
    sign_in @eleve
    get root_path
    refute_match "appel non validé", response.body
    refute_match "seance--attente", response.body
  end

  private

  def seance(prof, debut)
    l = Lesson.create!(batch: @batch, ue: @ue, teacher: prof,
                       title: "TD-01 - Mécanique #{SecureRandom.hex(3)}",
                       starts_at: debut, ends_at: debut + 2.hours)
    LessonGroup.create!(lesson: l, group: @groupe)
    l
  end
end
