require "test_helper"

# Les motifs sont portés par la feuille de style : un test de vue ne verrait
# rien. On vérifie donc qu'ils compilent et qu'ils sont posés là où il faut.
class MotifsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def css
    @css ||= Rails.application.assets["application.css"].to_s
  end

  test "les trois motifs compilent avec la couleur de la charte" do
    assert_match "M0 11 L8 2", css, "la frise de triangles"
    assert_match "M32 0 L64 32", css, "la trame de losanges"
    assert_match "M0 6 H24", css, "le tressage"
    assert_match(/%232c6eb8/i, css, "la couleur doit être interpolée dans le SVG")
  end

  test "les motifs habillent le bandeau, le pied de page et les titres" do
    assert_match ".band::before", css
    assert_match ".footer::before", css
    assert_match ".agenda__vide", css
  end

  test "une frise sépare l'accueil de la suite" do
    montrer_les_erreurs!
    batch = Batch.create!(title: "Promo motifs #{SecureRandom.hex(4)}")
    sign_in creer_eleve("84000001", batch: batch)
    get root_path
    assert_response :success
    assert_match "frise frise--fondue", response.body
    assert_match 'aria-hidden="true"', response.body, "un motif décoratif reste muet pour un lecteur d'écran"
  end
end
