require "test_helper"

class CalendrierTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Rails.application.env_config["action_dispatch.show_exceptions"] = :none
    @batch = Batch.create!(title: "Promo cal #{SecureRandom.hex(4)}")
    @ue = Ue.create!(batch: @batch, name: "Maths")
    @autre_ue = Ue.create!(batch: @batch, name: "Option non suivie")
    @groupe = Group.create!(ue: @ue, label: "TD-01", kind: :td)
    Group.create!(ue: @autre_ue, label: "TD-01", kind: :td)

    @eleve = User.create!(email: "cal-#{SecureRandom.hex(4)}@etudiant.upf.pf", first_name: "A",
                          last_name: "B", student_number: "92000001", batch: @batch, password: "motdepasse")
    GroupMembership.create!(user: @eleve, group: @groupe)

    @lundi = Date.current.beginning_of_week
    @td = seance(@ue, @groupe, @lundi, 8, 2)
  end

  test "la semaine affiche les séances de l'étudiant" do
    sign_in @eleve
    get calendrier_path
    assert_response :success
    assert_match "Maths", response.body
    assert_match "cal__seance", response.body
    assert_match "TD-01", response.body
  end

  test "l'accueil mène au calendrier, à côté des matières" do
    sign_in @eleve
    get root_path
    assert_match calendrier_path, response.body
    assert_match matieres_path, response.body
  end

  test "un CM d'une UE non suivie n'apparaît pas, un événement sans matière si" do
    seance(@autre_ue, nil, @lundi, 10, 2)                     # CM d'une option : non
    evenement = seance(nil, nil, @lundi, 14, 1, titre: "Réunion de rentrée")  # sans UE : oui
    sign_in @eleve
    get calendrier_path
    refute_match "Option non suivie", response.body
    assert_match "Réunion de rentrée", response.body
    assert_equal 2, Calendrier.new(@eleve).seances.size
  end

  test "on navigue d'une semaine à l'autre" do
    sign_in @eleve
    get calendrier_path(semaine: (@lundi + 7).to_s)
    assert_response :success
    assert_match(/Aujourd/, response.body, "un retour au jour même est proposé")
    refute_match "cal__seance", response.body, "la semaine suivante est vide"
  end

  test "une date illisible ramène sur la semaine courante" do
    sign_in @eleve
    get calendrier_path(semaine: "pas-une-date")
    assert_response :success
    assert_match "cal__seance", response.body, "on retombe sur la semaine en cours"
  end

  test "les séances sont placées au bon endroit dans la grille" do
    c = Calendrier.new(@eleve, date: @lundi)
    pos = c.position(@td)
    heures = c.plage.last - c.plage.first
    attendu = 100.0 * (8 - c.plage.first) / heures
    assert_in_delta attendu, pos[:haut], 0.01
    assert_in_delta 100.0 * 2 / heures, pos[:hauteur], 0.01
  end

  private

  def seance(ue, groupe, jour, heure, duree, titre: nil)
    debut = jour.to_time.change(hour: heure)
    l = Lesson.create!(batch: @batch, ue: ue, ade_uid: SecureRandom.hex(8),
                       title: titre || "#{groupe&.label || 'CM'} - #{ue&.name}",
                       category: groupe ? :td : :cm, starts_at: debut, ends_at: debut + duree.hours)
    LessonGroup.create!(lesson: l, group: groupe) if groupe
    l
  end
end
