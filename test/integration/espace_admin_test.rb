require "test_helper"

# Les pages réservées à l'administration : soutien, avancement, suivi et
# l'écran de l'étudiant. La fiche, elle, est ouverte au corps enseignant.
class EspaceAdminTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    montrer_les_erreurs!
    @batch = Batch.create!(title: "Promo admin #{SecureRandom.hex(4)}")
    ref = Referential.create!(title: "Réf", batch: @batch, active: true)
    bloc = SkillBlock.create!(referential: ref, title: "B", position: 1)
    Skill.create!(skill_block: bloc, title: "C", position: 1)
    @projet = Project.create!(batch: @batch, name: "Sujet", description: "d",
                              max_booking: 4, subject: :physique)

    @ue = Ue.create!(batch: @batch, name: "Mécanique", code: "1.3", position: 3)
    @groupe = Group.create!(ue: @ue, label: "TD-01", kind: :td)

    @prof = creer_prof
    @admin = creer_prof("Serafini")
    @admin.update!(admin: true)

    @eleve = creer_eleve("86000001", "Amaru")
    GroupMembership.create!(user: @eleve, group: @groupe)
    @team = Team.create!(name: "Équipe admin #{SecureRandom.hex(3)}", project: @projet, user: @eleve)
    @eleve.update!(team: @team, speciality: nil)

    @passee = Lesson.create!(batch: @batch, ue: @ue, teacher: @prof, title: "TD-01 - Mécanique",
                             starts_at: 2.days.ago, ends_at: 2.days.ago + 2.hours)
    LessonGroup.create!(lesson: @passee, group: @groupe)
    @passee.attendances.create!(user: @eleve, status: :present, declared_by: :teacher)

    UeAssessment.create!(user: @eleve, ue: @ue, level: :initiation, home_hours: 3.5)
    TutoringRequest.create!(user: @eleve, ue: @ue)
  end

  # --- les portes ---

  test "le soutien et son avancement sont réservés à l'administration" do
    sign_in @prof
    get teacher_soutien_path
    assert_redirected_to root_path
    get avancement_teacher_soutien_path
    assert_redirected_to root_path
  end

  # Lire le dossier d'un étudiant est le travail de tout enseignant ; se mettre
  # à sa place devant l'écran où il se déclare ne l'est pas.
  test "la fiche s'ouvre aux enseignants, l'écran de l'étudiant non" do
    sign_in @prof
    get teacher_etudiant_path(@eleve)
    assert_response :success

    get matieres_teacher_etudiant_path(@eleve)
    assert_redirected_to root_path
  end

  test "un étudiant n'atteint aucune de ces pages" do
    sign_in @eleve
    [teacher_soutien_path, avancement_teacher_soutien_path, teacher_suivi_path,
     teacher_etudiant_path(@eleve), matieres_teacher_etudiant_path(@eleve)].each do |chemin|
      get chemin
      assert_redirected_to root_path, chemin
    end
  end

  test "la barre de navigation ne propose ces pages qu'à l'administrateur" do
    sign_in @prof
    get root_path
    refute_match teacher_soutien_path, response.body
    refute_match teacher_suivi_path, response.body

    sign_out :user
    sign_in @admin
    get root_path
    assert_match teacher_soutien_path, response.body
  end

  test "le lien vers le suivi vit sur la page des présences" do
    sign_in @admin
    get teacher_bilan_path
    assert_match teacher_suivi_path, response.body

    sign_out :user
    sign_in @prof
    get teacher_bilan_path
    refute_match teacher_suivi_path, response.body
  end

  # --- le contenu ---

  test "le soutien réunit les chiffres et le détail nominatif" do
    sign_in @admin
    get teacher_soutien_path(batch_id: @batch.id)
    assert_response :success
    assert_match "étudiant concerné", response.body
    assert_match "La demande par matière", response.body
    assert_match "Qui a demandé quoi", response.body
    assert_match @eleve.email, response.body
    assert_match "Avancement des étudiants", response.body, "l'onglet vers l'autre vue"
  end

  test "l'avancement compte ce que les étudiants ont rempli" do
    muet = creer_eleve("86000002", "Muet")
    GroupMembership.create!(user: muet, group: @groupe)

    sign_in @admin
    get avancement_teacher_soutien_path(batch_id: @batch.id)
    assert_response :success
    assert_match "des étudiants ont rempli au moins une matière", response.body
    assert_match @eleve.last_name.upcase, response.body
    assert_match muet.last_name.upcase, response.body
    assert_match "N&#39;a rien rempli", response.body
  end

  test "le suivi montre l'assiduité des étudiants" do
    sign_in @admin
    get teacher_suivi_path(batch_id: @batch.id)
    assert_response :success
    assert_match "L'assiduité des étudiants", response.body.gsub("&#39;", "'")
    assert_match "Couverture", response.body
    assert_match @eleve.last_name.upcase, response.body
  end

  test "la fiche d'un étudiant réunit tout ce que la plateforme sait de lui" do
    sign_in @admin
    get teacher_etudiant_path(@eleve)
    assert_response :success

    assert_match @eleve.last_name.upcase, response.body
    assert_match @eleve.email, response.body
    assert_match @eleve.student_number, response.body
    assert_match @team.name, response.body
    assert_match team_path(@team), response.body, "un lien vers son équipe"
    assert_match "Mécanique", response.body
    assert_match "Initiation", response.body, "son niveau déclaré"
    assert_match "3.5 h", response.body, "son travail personnel"
    assert_match "Ses derniers pointages", response.body
    assert_match "demande de soutien", response.body
  end

  test "la fiche tient pour un étudiant sans rien" do
    nu = creer_eleve("86000003", "Vide")
    sign_in @admin
    get teacher_etudiant_path(nu)
    assert_response :success
    assert_match "Aucune équipe", response.body
    assert_match "Rattaché à aucun groupe", response.body
  end

  test "la fiche d'un enseignant n'existe pas" do
    sign_in @admin
    assert_raises(ActiveRecord::RecordNotFound) { get teacher_etudiant_path(@prof) }
  end
end
