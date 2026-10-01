require "test_helper"

class SuiviEmargementTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    montrer_les_erreurs!
    @batch = Batch.create!(title: "Promo suivi #{SecureRandom.hex(4)}")
    @ue = Ue.create!(batch: @batch, name: "Mécanique", code: "1.3", position: 3)
    @groupe = Group.create!(ue: @ue, label: "TD-01", kind: :td)
    @eleve = creer_eleve("83000001", "Amaru")
    GroupMembership.create!(user: @eleve, group: @groupe)

    @admin = creer_prof("Serafini")
    @admin.update!(admin: true)
    @assidu = creer_prof("Adam")
    @absent = creer_prof("Ortega")

    # L'assidu : deux séances, deux appels, un validé.
    @a1 = seance(@assidu, 5.days.ago)
    @a2 = seance(@assidu, 3.days.ago)
    [@a1, @a2].each { |l| l.attendances.create!(user: @eleve, status: :present, declared_by: :teacher) }
    @a1.valider!

    # Celui qui n'a jamais ouvert la feuille : trois séances, aucun appel.
    @o1 = seance(@absent, 4.days.ago)
    @o2 = seance(@absent, 2.days.ago)
    @o3 = seance(@absent, 1.day.ago)

    # Un intervenant nommé par ADE sans compte.
    @sans = seance(nil, 6.days.ago, label: "Mousson Namata (Mme)")

    # Et une séance à venir, qui ne doit pas peser dans le calcul.
    seance(@absent, 2.days.from_now)
  end

  test "seul l'administrateur ouvre le suivi" do
    sign_in @assidu
    get teacher_suivi_path(batch_id: @batch.id)
    assert_redirected_to root_path

    sign_out @assidu
    sign_in @eleve
    get teacher_suivi_path
    assert_redirected_to root_path
  end

  test "le taux ne compte que les séances déjà commencées" do
    suivi = SuiviEmargement.new(@batch)
    assert_equal 6, suivi.seances, "la séance à venir est hors du calcul"
    assert_equal 2, suivi.appelees
    assert_equal 1, suivi.validees
    assert_equal 33, suivi.taux
  end

  test "chaque intervenant reçoit un état lisible" do
    lignes = SuiviEmargement.new(@batch).lignes.index_by(&:libelle)

    assert_equal :regulier, lignes["Adam Test"].etat
    assert_equal 100, lignes["Adam Test"].taux
    assert_equal @a2.starts_at.to_date, lignes["Adam Test"].dernier_appel.to_date

    assert_equal :jamais, lignes["Ortega Test"].etat
    assert_equal 0, lignes["Ortega Test"].taux
    assert_nil lignes["Ortega Test"].dernier_appel

    assert_equal :sans_compte, lignes["Mousson Namata"].etat
  end

  # Une séance renseignée depuis l'onglet Présences compte autant qu'un appel
  # pris en salle : dans les deux cas le registre est tenu.
  test "une séance renseignée depuis le relevé compte comme tenue" do
    releve = seance(@absent, 7.days.ago)
    releve.attendances.create!(user: @eleve, status: :present, declared_by: :teacher)

    suivi = SuiviEmargement.new(@batch)
    ligne = suivi.lignes.find { |l| l.libelle == "Ortega Test" }
    assert_equal 1, ligne.appelees
    assert_equal 0, ligne.en_seance, "aucun code n'a été posé : l'appel n'a pas été ouvert"
    assert_equal 1, ligne.apres_coup
  end

  test "les deux pratiques se distinguent sans se confondre" do
    @a1.update!(attendance_code: "1234")   # appel ouvert en salle
    releve = seance(@assidu, 8.days.ago)   # renseigné après coup
    releve.attendances.create!(user: @eleve, status: :present, declared_by: :teacher)

    suivi = SuiviEmargement.new(@batch)
    ligne = suivi.lignes.find { |l| l.libelle == "Adam Test" }
    assert_equal 3, ligne.appelees
    assert_equal 1, ligne.en_seance
    assert_equal 2, ligne.apres_coup
    assert_equal ligne.appelees, ligne.en_seance + ligne.apres_coup
  end

  test "la page explique la différence entre les deux colonnes" do
    sign_in @admin
    get teacher_suivi_path(batch_id: @batch.id)
    assert_match "En salle", response.body
    assert_match "Après coup", response.body
    assert_match "quelle pratique s'installe", response.body
  end

  test "les intervenants sont classés par volume de séances" do
    libelles = SuiviEmargement.new(@batch).lignes.map(&:libelle)
    assert_equal "Ortega Test", libelles.first, "trois séances, c'est là que ça pèse"
  end

  test "la page montre les chiffres, les états et les séances sans appel" do
    sign_in @admin
    get teacher_suivi_path(batch_id: @batch.id)
    assert_response :success

    assert_match "Suivi de l'émargement", response.body
    assert_match "Réservée à l'administration", response.body.gsub("réservée", "Réservée")
    assert_match "Adam Test", response.body
    assert_match "Jamais", response.body
    assert_match "Sans compte", response.body
    assert_match "Les dernières séances sans appel", response.body
    assert_match @o3.title, response.body
    refute_match @a1.title, response.body, "une séance appelée n'est pas dans les manquantes"
  end

  test "les semaines donnent un taux par semaine" do
    semaines = SuiviEmargement.new(@batch).semaines(2)
    assert_equal 2, semaines.size
    assert semaines.last[:seances].positive?
    assert_not_nil semaines.last[:taux]
  end

  # Le lien a quitté la barre de navigation pour la page des présences : c'est
  # en tenant son registre qu'on se demande où en sont les autres.
  test "le lien du suivi vit sur la page des présences, pour l'administrateur seul" do
    sign_in @admin
    get teacher_bilan_path
    assert_match teacher_suivi_path, response.body
    get root_path
    refute_match teacher_suivi_path, response.body, "plus dans la barre de navigation"

    sign_out :user
    sign_in @assidu
    get teacher_bilan_path
    refute_match teacher_suivi_path, response.body
  end

  test "l'administrateur voit le nom de l'intervenant à côté de chaque cours" do
    sign_in @admin
    get root_path
    assert_match "seance__prof", response.body

    # Y compris dans la vue restreinte à ses propres séances.
    seance(@admin, 1.hour.from_now)
    get root_path(cours: "miens")
    assert_match "seance__prof", response.body
  end

  private

  def seance(prof, debut, label: nil)
    Lesson.create!(batch: @batch, ue: @ue, teacher: prof, starts_at: debut, ends_at: debut + 2.hours,
                   title: "TD-01 - Mécanique #{SecureRandom.hex(3)}",
                   teacher_label: label || (prof && "#{prof.last_name} #{prof.first_name} (M.)"))
  end
end
