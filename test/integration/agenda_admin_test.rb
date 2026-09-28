require "test_helper"

class AgendaAdminTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    montrer_les_erreurs!
    @batch = Batch.create!(title: "Promo agenda #{SecureRandom.hex(4)}")
    @ue = Ue.create!(batch: @batch, name: "Calcul fonctionnel", code: "1.2", position: 1)

    @admin = creer_prof("Serafini")
    @admin.update!(admin: true)
    @collegue = creer_prof("Adam")
    @simple = creer_prof("Ortega")   # enseignant sans droits d'administration

    @mienne = seance("TD-01 - Calcul fonctionnel", @admin, 2.hours.from_now)
    @sienne = seance("TD-02 - Calcul fonctionnel", @collegue, 4.hours.from_now)
    @orpheline = seance("TD-03 - Calcul fonctionnel", nil, 6.hours.from_now,
                        label: "Mousson Namata (Mme)")
    @passee = seance("TD-04 - Calcul fonctionnel", @collegue, 3.days.ago)
  end

  test "l'administrateur voit par défaut toutes les séances de la promotion" do
    sign_in @admin
    get root_path
    assert_response :success
    assert_match "Les cours de la promotion", response.body
    assert_match @mienne.title, response.body
    assert_match @sienne.title, response.body
    assert_match @orpheline.title, response.body
    refute_match @passee.title, response.body, "les séances passées restent hors de l'agenda"
  end

  test "l'intervenant est nommé quand on regarde au-delà des siennes" do
    sign_in @admin
    get root_path
    assert_match "Adam", response.body
    assert_match "sans compte enseignant", response.body
  end

  test "le filtre ramène l'administrateur à ses seules séances" do
    sign_in @admin
    get root_path(cours: "miens")
    assert_response :success
    assert_match "Mes cours", response.body
    assert_match @mienne.title, response.body
    refute_match @sienne.title, response.body
    refute_match @orpheline.title, response.body
  end

  test "les deux onglets ne sont proposés qu'à l'administrateur" do
    sign_in @admin
    get root_path
    assert_match "agenda__filtre", response.body
    assert_match "Tous les cours", response.body

    sign_out @admin
    sign_in @simple
    get root_path
    refute_match "agenda__filtre", response.body
  end

  test "un enseignant ordinaire ne voit que les siennes, même en forçant l'adresse" do
    sign_in @simple
    get root_path(cours: "tous")
    assert_response :success
    assert_match "Mes cours", response.body
    refute_match @sienne.title, response.body
    refute_match @mienne.title, response.body
  end

  test "un étudiant n'est pas concerné par le filtre" do
    eleve = creer_eleve("60000021")
    sign_in eleve
    get root_path(cours: "tous")
    assert_response :success
    refute_match "agenda__filtre", response.body
  end

  test "depuis la liste, l'administrateur ouvre la feuille d'un collègue" do
    sign_in @admin
    get root_path
    assert_match teacher_lesson_path(@sienne), response.body
    get teacher_lesson_path(@sienne)
    assert_response :success
  end

  private

  def seance(titre, prof, debut, label: nil)
    Lesson.create!(batch: @batch, ue: @ue, teacher: prof, title: titre,
                   teacher_label: label || (prof && "#{prof.last_name} #{prof.first_name} (M.)"),
                   starts_at: debut, ends_at: debut + 2.hours)
  end
end
