require "test_helper"

# `subject` est un enum positionnel : la colonne stocke l'indice. Ce test
# fige l'ordre des quatre premières valeurs — les réordonner changerait la
# catégorie de tous les projets déjà en base sans qu'aucune migration passe.
class SujetsProjetTest < ActiveSupport::TestCase
  test "les quatre disciplines gardent leur indice d'origine" do
    assert_equal 0, Project.subjects["physique"]
    assert_equal 1, Project.subjects["chimie"]
    assert_equal 2, Project.subjects["stes"]
    assert_equal 3, Project.subjects["maths"]
  end

  test "les quatre sujets de science des données s'ajoutent à la suite" do
    assert_equal 4, Project.subjects["regression_lineaire"]
    assert_equal 5, Project.subjects["classification"]
    assert_equal 6, Project.subjects["clustering"]
    assert_equal 7, Project.subjects["deep_learning"]
    assert_equal 8, Project.subjects.size
  end

  test "chaque sujet a un libellé lisible" do
    batch = Batch.create!(title: "Promo sujets #{SecureRandom.hex(4)}")
    { "regression_lineaire" => "Régression linéaire",
      "deep_learning" => "Deep learning",
      "stes" => "STES",
      "clustering" => "Clustering" }.each do |cle, libelle|
      p = Project.create!(batch: batch, name: "P #{cle}", description: "d",
                          max_booking: 1, subject: cle)
      assert_equal libelle, p.subject_label
      refute_match(/_/, p.subject_label, "aucun souligné ne doit s'afficher")
    end
  end

  test "une pastille existe pour chaque sujet" do
    css = File.read(Rails.root.join("app/assets/stylesheets/application.scss"))
    Project.subjects.each_key do |cle|
      assert_match ".bg-#{cle} ", css, "il manque la couleur de #{cle}"
    end
  end
end
