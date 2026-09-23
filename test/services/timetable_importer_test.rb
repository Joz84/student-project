require "test_helper"

class TimetableImporterTest < ActiveSupport::TestCase
  setup do
    @batch = Batch.create!(title: "Promo import #{SecureRandom.hex(4)}")
  end

  # ADE a changé de schéma d'UID en cours d'année : aucun identifiant d'un
  # export ne se retrouvait dans le suivant. Keyer dessus dupliquait tout le
  # calendrier à chaque passage, ce qui est arrivé en production.
  test "un changement d'UID ne duplique pas les séances" do
    importer(ics("PREMIER")).run
    assert_equal 2, Lesson.where(batch: @batch).count

    importer(ics("SECOND")).run
    assert_equal 2, Lesson.where(batch: @batch).count, "la même séance sous un autre UID reste la même séance"
  end

  test "deux passages identiques ne changent rien" do
    importer(ics("A")).run
    r = importer(ics("A")).run
    assert_equal 0, r.creees
    assert_equal 0, r.majs
    assert_equal 2, r.inchangees
  end

  test "une séance retirée d'ADE est supprimée" do
    importer(ics("A")).run
    r = importer(ics("A", une_seule: true)).run
    assert_equal 1, r.supprimees
    assert_equal 1, Lesson.where(batch: @batch).count
  end

  test "une séance retirée d'ADE mais déjà pointée est conservée" do
    importer(ics("A")).run
    seance = Lesson.where(batch: @batch).order(:starts_at).last
    eleve = User.create!(email: "e-#{SecureRandom.hex(4)}@etudiant.upf.pf", first_name: "X",
                         last_name: "Y", student_number: "99999999", batch: @batch,
                         password: "motdepasse")
    Attendance.create!(lesson: seance, user: eleve, status: :present, declared_by: :teacher)

    r = importer(ics("A", une_seule: true)).run
    assert_equal 0, r.supprimees
    assert_equal 1, r.conservees
    assert Lesson.exists?(seance.id), "on ne détruit pas une séance dont l'appel est fait"
  end

  test "un horaire déplacé donne une nouvelle séance et retire l'ancienne" do
    importer(ics("A")).run
    ancienne = Lesson.where(batch: @batch).order(:starts_at).first
    r = importer(ics("A", decale: true)).run
    assert_equal 1, r.creees
    assert_equal 1, r.supprimees
    refute Lesson.exists?(ancienne.id)
  end

  private

  def importer(contenu)
    TimetableImporter.new(@batch, ["peu-importe"]).tap do |i|
      i.define_singleton_method(:codes_ics) { [contenu] }
      AdeCalendar.define_singleton_method(:telecharger) { |_| contenu }
    end
  end

  def ics(prefixe, une_seule: false, decale: false)
    debut = decale ? "20261001T200000Z" : "20261001T190000Z"
    evs = [["#{prefixe}-1", debut, "20261001T203000Z", "TD-01 - Analyse", "G3-2"]]
    evs << ["#{prefixe}-2", "20261002T190000Z", "20261002T203000Z", "CM - Analyse", "AMPHI"] unless une_seule
    corps = evs.map do |uid, d, f, resume, salle|
      "BEGIN:VEVENT\nUID:#{uid}\nDTSTART:#{d}\nDTEND:#{f}\nSUMMARY:#{resume}\n" \
      "LOCATION:#{salle}\nDESCRIPTION:\\n\\n#{resume}\\nAdam David (M.)\\n\nEND:VEVENT"
    end.join("\n")
    "BEGIN:VCALENDAR\nVERSION:2.0\n#{corps}\nEND:VCALENDAR\n"
  end
end
