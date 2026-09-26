require "test_helper"

class MaquetteL1Test < ActiveSupport::TestCase
  setup do
    @batch = Batch.create!(title: "Promo maquette #{SecureRandom.hex(4)}")
  end

  test "les UE créées par l'import ADE reçoivent leur code officiel" do
    ade = Ue.create!(batch: @batch, name: "SPI : Géophysique")
    pix = Ue.create!(batch: @batch, name: "CNB PIX")

    MaquetteL1.new(@batch).appliquer!

    assert_equal "1.5.b", ade.reload.code, "l'intitulé d'ADE est rapproché du code"
    assert_equal "1.6.1", pix.reload.code
    assert_equal "SPI : Géophysique", ade.name, "on ne renomme pas ce à quoi des séances sont rattachées"
  end

  test "les enseignements absents d'ADE sont créés" do
    MaquetteL1.new(@batch).appliquer!
    anglais = Ue.find_by(batch: @batch, name: "Anglais")
    assert anglais.present?
    assert_equal "2.8", anglais.code
    assert_empty anglais.groups
  end

  test "rejouer ne duplique rien" do
    MaquetteL1.new(@batch).appliquer!
    avant = Ue.where(batch: @batch).count
    MaquetteL1.new(@batch).appliquer!
    assert_equal avant, Ue.where(batch: @batch).count
  end

  test "une UE hors maquette est signalée, pas supprimée" do
    intruse = Ue.create!(batch: @batch, name: "Atelier improvisé")
    r = MaquetteL1.new(@batch).appliquer!
    assert_includes r.orphelines, "Atelier improvisé"
    assert Ue.exists?(intruse.id)
  end

  test "la liste du menu est ordonnée et porte les codes" do
    MaquetteL1.new(@batch).appliquer!
    liste = MaquetteL1.pour_liste(@batch)
    assert_equal "1.1 — Calcul numérique et algébrique", liste.first.first
    assert_includes liste.map(&:first), "1.12 — Projet (REH)"
    assert_operator liste.map(&:first).index { |l| l.start_with?("1.") },
                    :<, liste.map(&:first).index { |l| l.start_with?("2.") }
  end

  test "une simulation n'écrit rien" do
    r = MaquetteL1.new(@batch).appliquer!(dry_run: true)
    assert_operator r.creees, :>, 0
    assert_equal 0, Ue.where(batch: @batch).count
  end
end
