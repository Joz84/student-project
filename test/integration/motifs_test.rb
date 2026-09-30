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

  test "quatre frises sont disponibles, le tressage par défaut" do
    assert_match "M0 9 Q10 1 20 9", css, "le tressage"
    assert_match "M0 12 Q9 2 18 12", css, "les vagues"
    assert_match "M0 4 L14 14 L28 4", css, "les chevrons"
    assert_match "M14 2 L26 9 L14 16", css, "les losanges"
    %w[frise--vagues frise--chevrons frise--losanges frise--triangles].each do |variante|
      assert_match variante, css
    end
  end

  test "la rose des vents se dessine et reste muette pour un lecteur d'écran" do
    rose = ApplicationController.render(partial: "shared/rose_des_vents")
    assert_match 'aria-hidden="true"', rose
    assert_match "rose__coeur", rose
    # 32 triangles de bordure, 8 rayons, 1 losange central.
    assert_equal 41, rose.scan("<polygon").size
    assert_equal 32, rose.scan("<line").size, "les 32 maisons d'étoiles"
  end

  test "elle porte un nom quand on lui en donne un" do
    rose = ApplicationController.render(partial: "shared/rose_des_vents",
                                        locals: { titre: "Rose des vents" })
    assert_match 'role=img', rose
    refute_match 'aria-hidden', rose
  end

  test "elle coiffe les trois pages de l'équipe" do
    montrer_les_erreurs!
    batch = Batch.create!(title: "Promo rose #{SecureRandom.hex(4)}")
    ref = Referential.create!(title: "Réf", batch: batch, active: true)
    bloc = SkillBlock.create!(referential: ref, title: "B", position: 1)
    Skill.create!(skill_block: bloc, title: "C", position: 1)
    projet = Project.create!(batch: batch, name: "S", description: "d", max_booking: 4, subject: :physique)
    eleve = creer_eleve("84000002", batch: batch)
    team = Team.create!(name: "Équipe rose #{SecureRandom.hex(3)}", project: projet, user: eleve)
    eleve.update!(team: team)
    sign_in eleve

    [team_path(team), team_roadmap_path(team), team_progressions_path(team)].each do |chemin|
      get chemin
      assert_response :success, chemin
      assert_match "entete-equipe__rose", response.body, chemin
    end
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
