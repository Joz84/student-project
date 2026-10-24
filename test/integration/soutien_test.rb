require "test_helper"

class SoutienTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    montrer_les_erreurs!
    @batch = Batch.create!(title: "Promo soutien #{SecureRandom.hex(4)}")
    @maths = Ue.create!(batch: @batch, name: "Calcul fonctionnel")
    @chimie = Ue.create!(batch: @batch, name: "Structure de la matière")
    @option = Ue.create!(batch: @batch, name: "Option non suivie")
    @g_maths = Group.create!(ue: @maths, label: "TD-01", kind: :td)
    @g_chimie = Group.create!(ue: @chimie, label: "TD-01", kind: :td)
    Group.create!(ue: @option, label: "TP-01-OPTION1", kind: :option)

    @eleve = creer_eleve("80000001", "Tetua")
    GroupMembership.create!(user: @eleve, group: @g_maths)
    GroupMembership.create!(user: @eleve, group: @g_chimie)
    @camarade = creer_eleve("80000002", "Avae")
    GroupMembership.create!(user: @camarade, group: @g_maths)

    @prof = creer_prof
    @admin = creer_prof("Serafini")
    @admin.update!(admin: true)
    [@maths, @chimie].each { |ue| seance(ue) }
  end

  test "l'étudiant voit un bouton de soutien par matière" do
    sign_in @eleve
    get matieres_path
    assert_response :success
    assert_equal 2, response.body.scan("Je souhaite du soutien").size
    assert_match "Seuls les enseignants voient votre demande", response.body
  end

  test "un bandeau annonce le dispositif, et compte les inscriptions" do
    sign_in @eleve
    get matieres_path
    assert_match "Besoin d'un coup de main ?", response.body
    assert_match "avec le bouton vert", response.body

    TutoringRequest.create!(user: @eleve, ue: @maths)
    get matieres_path
    assert_match "Vous êtes inscrit sur", response.body
    assert_match "1 matière", response.body
    refute_match "avec le bouton vert", response.body
  end

  test "le bouton bascule la demande et la retire" do
    sign_in @eleve
    assert_difference -> { TutoringRequest.count }, 1 do
      post ue_tutoring_request_path(@maths)
    end
    assert_redirected_to matieres_path
    assert TutoringRequest.demandee?(@eleve, @maths)

    assert_difference -> { TutoringRequest.count }, -1 do
      post ue_tutoring_request_path(@maths)
    end
    refute TutoringRequest.demandee?(@eleve, @maths)
  end

  test "la page montre l'état courant du bouton" do
    TutoringRequest.create!(user: @eleve, ue: @maths)
    sign_in @eleve
    get matieres_path
    assert_match "Inscrit au soutien", response.body
    assert_match "soutien-btn--prise", response.body
    assert_match "me retirer", response.body
    assert_match "Je souhaite du soutien", response.body   # l'autre matière
  end

  test "on ne demande pas du soutien sur une UE qu'on ne suit pas" do
    sign_in @eleve
    assert_no_difference -> { TutoringRequest.count } do
      post ue_tutoring_request_path(@option)
    end
    assert_redirected_to root_path
  end

  test "un enseignant ne s'inscrit pas au soutien" do
    sign_in @prof
    assert_no_difference -> { TutoringRequest.count } do
      post ue_tutoring_request_path(@maths)
    end
    assert_redirected_to root_path
  end

  test "une même demande ne se dédouble pas" do
    TutoringRequest.create!(user: @eleve, ue: @maths)
    doublon = TutoringRequest.new(user: @eleve, ue: @maths)
    refute doublon.valid?
  end

  test "la demande est classée du moins avancé au plus avancé" do
    UeAssessment.create!(user: @eleve, ue: @maths, level: :application)
    TutoringRequest.create!(user: @eleve, ue: @maths)
    TutoringRequest.create!(user: @camarade, ue: @maths)   # sans niveau déclaré

    sign_in @admin
    get teacher_soutien_path(batch_id: @batch.id)
    assert_response :success
    assert_match "Calcul fonctionnel", response.body
    assert_match @eleve.email, response.body
    assert_match "non déclaré", response.body
    # Le camarade, qui ne s'est pas situé, passe avant celui qui se dit à l'aise.
    assert_operator response.body.index("AVAE"), :<, response.body.index("TETUA")
  end

  test "les matières sans demande sont reléguées en bas" do
    TutoringRequest.create!(user: @eleve, ue: @maths)
    sign_in @admin
    get teacher_soutien_path(batch_id: @batch.id)
    assert_match "Aucune demande sur ces matières", response.body
    assert_match "Structure de la matière", response.body
  end

  test "sans aucune demande la page le dit" do
    sign_in @admin
    get teacher_soutien_path(batch_id: @batch.id)
    assert_response :success
    assert_match "Aucune demande pour le moment", response.body
  end

  # Une matière qui a des TD et des TP comptait deux fois chaque étudiant :
  # 132 inscrits affichés pour une promotion de 87, et une part divisée par
  # deux dans le récapitulatif.
  test "l'effectif d'une matière compte les personnes, pas les appartenances" do
    tp = Group.create!(ue: @maths, label: "TP-01", kind: :tp)
    GroupMembership.create!(user: @eleve, group: tp)      # déjà dans le TD-01
    GroupMembership.create!(user: @camarade, group: tp)

    ligne = Soutien.new(@batch).lignes.find { |l| l.ue == @maths }
    assert_equal 2, ligne.suivi, "deux étudiants, quatre appartenances"
  end

  test "la part rapporte la demande à l'effectif réel" do
    TutoringRequest.create!(user: @eleve, ue: @maths)
    ligne = Soutien.new(@batch).lignes.find { |l| l.ue == @maths }
    assert_equal 2, ligne.suivi
    assert_equal 1, ligne.nombre
    assert_equal 50, ligne.taux
  end

  test "une matière sans inscrit n'a pas de part" do
    ligne = Soutien.new(@batch).lignes.find { |l| l.ue == @option }
    assert_equal 0, ligne.suivi
    assert_nil ligne.taux, "on ne divise pas par zéro, on n'affiche rien"
  end

  test "un compte désactivé ne compte plus dans la demande" do
    TutoringRequest.create!(user: @eleve, ue: @maths)
    TutoringRequest.create!(user: @camarade, ue: @maths)
    @camarade.update!(drop: true)

    soutien = Soutien.new(@batch)
    ligne = soutien.lignes.find { |l| l.ue == @maths }
    assert_equal 1, ligne.nombre
    assert_equal 1, soutien.demandeurs
  end

  # L'administration a besoin de voir l'écran que l'étudiant a sous les yeux :
  # sa fiche dit ce qu'il a déclaré, pas où il l'a déclaré.
  test "la fiche propose de voir l'écran de l'étudiant" do
    sign_in @admin
    get teacher_etudiant_path(@eleve)
    assert_response :success
    assert_match matieres_teacher_etudiant_path(@eleve), response.body
  end

  test "l'écran de l'étudiant montre ses demandes de soutien, en lecture seule" do
    TutoringRequest.create!(user: @eleve, ue: @maths)
    UeAssessment.create!(user: @eleve, ue: @chimie, level: :notion)

    sign_in @admin
    get matieres_teacher_etudiant_path(@eleve)
    assert_response :success
    assert_match "Vue de l'étudiant", response.body
    assert_match "TETUA", response.body
    assert_match "Inscrit au soutien", response.body       # son état, pas le nôtre
    assert_match "soutien-btn--inerte", response.body
    assert_match "autoeval__bouton--inerte", response.body
    refute_match "me retirer", response.body               # rien ne s'annule à sa place
    refute_match "matiere__effacer", response.body
  end

  # Le formulaire enregistrerait au nom de l'administrateur : son niveau
  # déclaré n'appartient qu'à l'étudiant.
  test "l'aperçu ne soumet rien au nom de l'administrateur" do
    sign_in @admin
    get matieres_teacher_etudiant_path(@eleve)
    assert_no_difference -> { UeAssessment.count } do
      get matieres_teacher_etudiant_path(@eleve)
    end
    assert_equal 0, UeAssessment.where(user: @admin).count
  end

  test "un enseignant qui n'est pas administrateur ne voit pas cet écran" do
    sign_in @prof
    get matieres_teacher_etudiant_path(@eleve)
    assert_redirected_to root_path
  end

  test "un étudiant ne voit pas l'écran d'un autre" do
    sign_in @camarade
    get matieres_teacher_etudiant_path(@eleve)
    assert_redirected_to root_path
  end

  test "un étudiant n'accède pas au relevé des demandes" do
    sign_in @eleve
    get teacher_soutien_path
    assert_redirected_to root_path
  end

  test "un visiteur non connecté non plus" do
    get teacher_soutien_path
    assert_redirected_to new_user_session_path
  end

  private

  def seance(ue)
    l = Lesson.create!(batch: @batch, ue: ue, teacher: @prof, title: "TD-01 - #{ue.name}",
                       starts_at: 2.days.ago, ends_at: 2.days.ago + 2.hours)
    LessonGroup.create!(lesson: l, group: ue.groups.first)
    l
  end
end
