require "test_helper"

class ImportRunTest < ActiveSupport::TestCase
  test "une exécution réussie se résume et compte comme à jour" do
    r = ImportRun.create!(source: "dip-X", started_at: 2.hours.ago, finished_at: 2.hours.ago + 3,
                          created_count: 2, updated_count: 1, unchanged_count: 400, deleted_count: 3)
    assert_match "2 créées", r.resume
    assert_match "3 supprimées", r.resume
    refute r.echec?
    assert ImportRun.a_jour?
  end

  test "une exécution en échec est signalée et ne vaut pas mise à jour" do
    ImportRun.create!(source: "dip-X", started_at: 1.hour.ago, error: "Net::ReadTimeout")
    assert ImportRun.recentes.first.echec?
    assert_nil ImportRun.derniere_reussite
    refute ImportRun.a_jour?, "une tâche qui plante ne doit pas passer pour une tâche qui tourne"
  end

  test "un import trop ancien n'est plus considéré à jour" do
    ImportRun.create!(source: "dip-X", started_at: 40.hours.ago, finished_at: 40.hours.ago + 2)
    refute ImportRun.a_jour?
    ImportRun.create!(source: "dip-X", started_at: 10.hours.ago, finished_at: 10.hours.ago + 2)
    assert ImportRun.a_jour?
  end

  test "sans aucune exécution, rien n'est à jour" do
    refute ImportRun.a_jour?
  end
end
