require "test_helper"

# Le sélecteur de promotions ne listait que celles qu'on encadre. Une promotion
# neuve, dont les projets n'ont pas encore d'encadrant, n'apparaissait donc dans
# le sélecteur de personne — pas même celui de l'administrateur.
class PromosVisiblesTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    montrer_les_erreurs!
    @batch = creer_promo("Promo encadrée")
    @neuve = creer_promo("Promo neuve")
    @projet = Project.create!(batch: @batch, name: "Sujet encadré", description: "d",
                              max_booking: 4, subject: :physique)
    @orphelin = Project.create!(batch: @neuve, name: "Projet 1", description: "d",
                                max_booking: 4, subject: :stes)

    @prof = creer_prof
    Supervision.create!(user: @prof, project: @projet)
    @admin = creer_prof("Direction")
    @admin.update!(admin: true)
    Supervision.create!(user: @admin, project: @projet)
  end

  def creer_promo(nom)
    b = Batch.create!(title: "#{nom} #{SecureRandom.hex(4)}")
    ref = Referential.create!(title: "Réf #{b.id}", batch: b, active: true)
    bloc = SkillBlock.create!(referential: ref, title: "B", position: 1)
    Skill.create!(skill_block: bloc, title: "C", position: 1)
    b
  end

  test "l'administrateur voit une promotion qu'il n'encadre pas" do
    sign_in @admin
    get teacher_teams_path(batch_id: @batch.id)
    assert_response :success
    assert_match @neuve.title, response.body
    assert_match teacher_batch_teams_path(@neuve), response.body
  end

  test "un enseignant ne voit que les promotions qu'il encadre" do
    sign_in @prof
    get teacher_teams_path(batch_id: @batch.id)
    assert_response :success
    assert_match @batch.title, response.body
    refute_match @neuve.title, response.body
  end

  test "une équipe dont le projet n'a pas d'encadrant reste affichée" do
    eleve = creer_eleve("83000001", "Teriipaia", batch: @neuve)
    equipe = Team.create!(name: "Orpheline", project: @orphelin, user: eleve)
    eleve.update!(team: equipe)

    sign_in @admin
    get teacher_batch_teams_path(@neuve)
    assert_response :success
    assert_match "Équipes sans encadrant", response.body
    assert_match equipe.name, response.body
    assert_match eleve.last_name, response.body
  end

  test "une équipe encadrée ne tombe pas dans le bloc sans encadrant" do
    eleve = creer_eleve("83000002", "Vahine", batch: @batch)
    equipe = Team.create!(name: "Encadrée", project: @projet, user: eleve)
    eleve.update!(team: equipe)

    sign_in @admin
    get teacher_batch_teams_path(@batch)
    assert_response :success
    assert_match equipe.name, response.body
    refute_match "Équipes sans encadrant", response.body
  end

  test "la pastille d'un sujet composé s'affiche lisiblement" do
    @projet.update!(subject: :regression_lineaire)
    eleve = creer_eleve("83000003", "Mahuta", batch: @batch)
    equipe = Team.create!(name: "Datavore", project: @projet, user: eleve)
    eleve.update!(team: equipe)

    sign_in @admin
    get teacher_batch_teams_path(@batch)
    assert_response :success
    assert_match "Régression linéaire", response.body
    assert_match "bg-regression_lineaire", response.body
    refute_match "Regression_lineaire", response.body
  end
end
