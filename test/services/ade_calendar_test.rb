require "test_helper"

# Le flux iCalendar d'ADE est la seule source des emplois du temps. Tout ce
# qui suit — séances, groupes, appels — dépend de cette lecture.
class AdeCalendarTest < ActiveSupport::TestCase
  ICS = <<~'ICS'
    BEGIN:VCALENDAR
    BEGIN:VEVENT
    UID:ADE60-1
    DTSTART:20250924T173000Z
    DTEND:20250924T213000Z
    SUMMARY:TP-03INFO - Programmation im
     pérative
    LOCATION:C2-2
    DESCRIPTION:Lic Portail Maths SPI 1ère année\nTP-03INFO - Programmation impérative\nSerafini Jonathan (M.)
    END:VEVENT
    BEGIN:VEVENT
    UID:ADE60-2
    DTSTART:20250925T180000Z
    DTEND:20250925T200000Z
    SUMMARY:CM - Structure de la matière
    DESCRIPTION:CM - Structure de la matière\nOrtega Pascal (M.)
    END:VEVENT
    BEGIN:VEVENT
    UID:ADE60-3
    DTSTART:20251002T173000Z
    DTEND:20251002T193000Z
    SUMMARY:TD-01 / TD-02 - Calcul numérique et algébrique
    DESCRIPTION:TD-01 / TD-02 - Calcul numérique et algébrique\nLucas Franck (M.)
    END:VEVENT
    BEGIN:VEVENT
    UID:ADE60-4
    DTSTART:20251110T180000Z
    DTEND:20251110T200000Z
    SUMMARY:TD - SPI : Méthodes chimiques\, physiques
    DESCRIPTION:Examen 1ère chance\nTD-03 - Méthodes chimiques\nFerrucci Franco (M.)
    END:VEVENT
    BEGIN:VEVENT
    UID:ADE60-5
    SUMMARY:Séance sans date
    END:VEVENT
    BEGIN:VEVENT
    UID:ADE60-6
    DTSTART:20251117T180000Z
    DTEND:20251117T200000Z
    SUMMARY:Rattrapage encadré
    DESCRIPTION:TP-04 - Outils de conception 3D\nOrtega Pascal (M.)
    END:VEVENT
    END:VCALENDAR
  ICS

  setup { @seances = AdeCalendar.seances(ICS) }

  test "une séance sans date est ignorée" do
    assert_equal 5, @seances.size
    refute_includes @seances.map(&:uid), "ADE60-5"
  end

  test "les lignes repliées sont recollées avant lecture" do
    assert_equal "TP-03INFO - Programmation impérative", seance("ADE60-1").titre
  end

  test "les horaires UTC d'ADE sont ramenés à l'heure de Tahiti" do
    s = seance("ADE60-1")
    assert_equal "2025-09-24 07:30", s.debut.strftime("%Y-%m-%d %H:%M")
    assert_equal "2025-09-24 11:30", s.fin.strftime("%Y-%m-%d %H:%M")
    assert_equal "Pacific/Tahiti", s.debut.time_zone.name
  end

  test "le groupe, la salle et l'enseignant sont extraits" do
    s = seance("ADE60-1")
    assert_equal [{ label: "TP-03INFO", kind: :tp_info }], s.groupes
    assert_equal "C2-2", s.salle
    assert_equal "Serafini Jonathan (M.)", s.enseignant
    assert_equal :tp_info, s.categorie
  end

  test "un CM ne vise aucun groupe" do
    s = seance("ADE60-2")
    assert_empty s.groupes, "« CM » seul n'est pas un groupe"
    assert_equal :cm, s.categorie
    assert_equal "Structure de la matière", s.ue
  end

  test "une séance commune à deux groupes les porte tous les deux" do
    s = seance("ADE60-3")
    assert_equal %w[TD-01 TD-02], s.groupes.map { |g| g[:label] }
    assert_equal :td, s.categorie
    assert_equal "Calcul numérique et algébrique", s.ue
  end

  test "un examen est reconnu et les virgules échappées sont rendues" do
    s = seance("ADE60-4")
    assert_equal :exam, s.categorie
    assert_includes s.titre, "Méthodes chimiques, physiques"
  end

  test "l'intitulé de l'UE se rattrape dans la description" do
    # Un résumé qui ne porte pas la forme « groupe - UE » : le nom se lit alors
    # dans la description, qui la porte toujours.
    s = seance("ADE60-6")
    assert_equal "Outils de conception 3D", s.ue
    assert_equal [{ label: "TP-04", kind: :tp }], s.groupes
  end

  test "le numéro de groupe est complété à deux chiffres" do
    normalise = AdeCalendar.normaliser(["TP", "3", nil, nil])
    assert_equal "TP-03", normalise[:label]
    assert_equal :tp, normalise[:kind]
  end

  test "une option est un groupe de TD à part entière" do
    normalise = AdeCalendar.normaliser(["TD", "1", nil, "OPTION2"])
    assert_equal "TD-01-OPTION2", normalise[:label]
    assert_equal :option, normalise[:kind]
  end

  private

  def seance(uid) = @seances.find { |s| s.uid == uid }
end
