require "test_helper"

# La vue d'ensemble des étudiants : un tableau réorganisé selon le découpage
# qu'on veut lire — projet, TD, TP — et la porte d'entrée vers les fiches.
class EffectifsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    montrer_les_erreurs!
    @batch = Batch.create!(title: "Promo effectifs #{SecureRandom.hex(4)}")
    @maths = Ue.create!(batch: @batch, name: "Calcul fonctionnel")
    @td1 = Group.create!(ue: @maths, label: "TD-01", kind: :td)
    @td2 = Group.create!(ue: @maths, label: "TD-02", kind: :td)
    @tp1 = Group.create!(ue: @maths, label: "TP-01", kind: :tp)
    @info1 = Group.create!(ue: @maths, label: "TP-01INFO", kind: :tp_info)

    @prof = creer_prof
    @admin = creer_prof("Serafini")
    @admin.update!(admin: true)

    @projet = Project.create!(batch: @batch, name: "Hydroponie", description: "d",
                              max_booking: 4, subject: :physique)
    @equipe = Team.create!(name: "Les hydroponistes #{SecureRandom.hex(3)}",
                           user: @prof, project: @projet)

    @tetua = creer_eleve("80000001", "Tetua", team: @equipe)
    GroupMembership.create!(user: @tetua, group: @td1)
    GroupMembership.create!(user: @tetua, group: @tp1)
    GroupMembership.create!(user: @tetua, group: @info1)

    @avae = creer_eleve("80000002", "Avae")
    GroupMembership.create!(user: @avae, group: @td2)

    @sans_rien = creer_eleve("80000003", "Nohorai")
  end

  test "l'administrateur voit tous les étudiants de la promotion" do
    sign_in @admin
    get teacher_etudiants_path(batch_id: @batch.id)
    assert_response :success
    assert_match "TETUA", response.body
    assert_match "AVAE", response.body
    assert_match "NOHORAI", response.body
  end

  test "chaque nom renvoie vers la fiche de l'étudiant" do
    sign_in @admin
    get teacher_etudiants_path(batch_id: @batch.id)
    assert_match teacher_etudiant_path(@tetua), response.body

    get teacher_etudiant_path(@tetua)
    assert_response :success
  end

  test "le tableau se réorganise par TD, chaque groupe dans son bloc" do
    sign_in @admin
    get teacher_etudiants_path(batch_id: @batch.id, axe: "td")
    assert_response :success
    assert_match "TD-01", response.body
    assert_match "TD-02", response.body
    assert_match "Sans groupe de TD", response.body
    # Rangé par groupe : le TD-01 et son unique étudiant précèdent le TD-02.
    assert_operator response.body.index("TETUA"), :<, response.body.index("AVAE")
  end

  test "le regroupement par projet met l'équipe en tête de bloc" do
    sign_in @admin
    get teacher_etudiants_path(batch_id: @batch.id, axe: "projet")
    assert_match @equipe.name, response.body
    assert_match "Hydroponie", response.body
    assert_match "Sans équipe", response.body
  end

  test "un axe inconnu ne fait pas tomber la page" do
    sign_in @admin
    get teacher_etudiants_path(batch_id: @batch.id, axe: "n-importe-quoi")
    assert_response :success
  end

  # La teinte est ce qui permet de suivre un TP à l'œil quand le tableau est
  # rangé par projet : elle ne doit pas changer d'un onglet à l'autre.
  test "un groupe garde sa teinte d'un regroupement à l'autre" do
    effectifs = Effectifs.new(@batch)
    teinte = effectifs.teinte("td", "TD-01")
    assert teinte.present?
    assert_equal teinte, Effectifs.new(@batch).teinte("td", "TD-01")
    refute_equal teinte, effectifs.teinte("td", "TD-02")
  end

  test "un étudiant inscrit à deux TP forme son propre sous-ensemble" do
    tp2 = Group.create!(ue: @maths, label: "TP-02", kind: :tp)
    GroupMembership.create!(user: @tetua, group: tp2)

    paquets = Effectifs.new(@batch).paquets("tp")
    assert_includes paquets.map(&:libelle), "TP-01 / TP-02"
    refute_includes paquets.map(&:libelle), "TP-01"
  end

  test "une équipe sans projet se range après les équipes constituées" do
    attente = Team.create!(name: "En attente de projet #{SecureRandom.hex(3)}", user: @prof)
    @avae.update!(team: attente)

    paquets = Effectifs.new(@batch).paquets("projet")
    assert_equal [@equipe.name, attente.name, "Sans équipe"], paquets.map(&:libelle)
    assert_equal "aucun projet attribué", paquets[1].detail
  end

  # Savoir qui est dans quel TD, quel TP et quelle équipe est un outil de
  # travail courant : la liste s'ouvre à tous les enseignants.
  test "un enseignant voit la liste et le découpage de la promotion" do
    sign_in @prof
    get teacher_etudiants_path(batch_id: @batch.id, axe: "td")
    assert_response :success
    assert_match "TETUA", response.body
    assert_match "TD-01", response.body
    assert_match @equipe.name, response.body
    assert_match "Page réservée aux enseignants", response.body
  end

  # Préparer un entretien est le travail de tout enseignant : les indicateurs et
  # la fiche qu'ils résument s'ouvrent avec la liste.
  test "un enseignant voit les indicateurs et ouvre les fiches" do
    TutoringRequest.create!(user: @tetua, ue: @maths)
    UeAssessment.create!(user: @tetua, ue: @maths, level: :notion)

    sign_in @prof
    get teacher_etudiants_path(batch_id: @batch.id)
    assert_response :success
    assert_match "demandent du soutien", response.body
    assert_match teacher_etudiant_path(@tetua), response.body

    get teacher_etudiant_path(@tetua)
    assert_response :success
    assert_match "Fiche réservée aux enseignants", response.body
  end

  # Se mettre à la place de l'étudiant est autre chose que lire son dossier :
  # cet écran-là ne sort pas de l'administration.
  test "un enseignant n'ouvre pas l'écran de l'étudiant depuis la fiche" do
    sign_in @prof
    get teacher_etudiant_path(@tetua)
    refute_match matieres_teacher_etudiant_path(@tetua), response.body

    get matieres_teacher_etudiant_path(@tetua)
    assert_redirected_to root_path
  end

  # Les boutons de l'écran de l'étudiant n'enregistrent qu'au nom du compte
  # connecté : un enseignant qui les atteindrait se créerait un relevé, ce qui
  # n'a aucun sens.
  test "un enseignant ne déclare pas de niveau ni de soutien" do
    sign_in @prof
    assert_no_difference -> { UeAssessment.count } do
      patch ue_assessment_path(@maths), params: { level: "maitrise" }
    end
    assert_redirected_to root_path

    assert_no_difference -> { TutoringRequest.count } do
      post ue_tutoring_request_path(@maths)
    end
    assert_redirected_to root_path
  end

  test "un étudiant n'entre ni dans la liste ni dans une fiche" do
    sign_in @tetua
    get teacher_etudiant_path(@avae)
    assert_redirected_to root_path
  end

  test "un étudiant n'entre pas, même en désignant une promotion" do
    sign_in @tetua
    get teacher_etudiants_path(batch_id: @batch.id)
    assert_redirected_to root_path
  end

  test "un visiteur non connecté non plus" do
    get teacher_etudiants_path
    assert_redirected_to new_user_session_path
  end
end
