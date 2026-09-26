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
    [@maths, @chimie].each { |ue| seance(ue) }
  end

  test "l'étudiant voit un bouton de soutien par matière" do
    sign_in @eleve
    get matieres_path
    assert_response :success
    assert_equal 2, response.body.scan("Je souhaite du soutien").size
    assert_match "Seuls les enseignants voient votre demande", response.body
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
    assert_match "Inscrit au soutien — me retirer", response.body
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

  test "l'enseignant voit la demande, classée du moins avancé au plus avancé" do
    UeAssessment.create!(user: @eleve, ue: @maths, level: :application)
    TutoringRequest.create!(user: @eleve, ue: @maths)
    TutoringRequest.create!(user: @camarade, ue: @maths)   # sans niveau déclaré

    sign_in @prof
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
    sign_in @prof
    get teacher_soutien_path(batch_id: @batch.id)
    assert_match "Aucune demande sur ces matières", response.body
    assert_match "Structure de la matière", response.body
  end

  test "sans aucune demande la page le dit" do
    sign_in @prof
    get teacher_soutien_path(batch_id: @batch.id)
    assert_response :success
    assert_match "Aucune demande pour le moment", response.body
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
