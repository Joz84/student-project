require "test_helper"

# Les référents rapportent qu'ils ne peuvent pas modifier les cartes de tâche.
# Ce test rejoue chacun de leurs gestes sur une équipe qu'ils encadrent.
class ReferentCartesTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    montrer_les_erreurs!
    @batch = Batch.create!(title: "Promo cartes #{SecureRandom.hex(4)}")
    ref = Referential.create!(title: "Réf", batch: @batch, active: true)
    bloc = SkillBlock.create!(referential: ref, title: "Bloc", position: 1)
    Skill.create!(skill_block: bloc, title: "Compétence", position: 1)
    @projet = Project.create!(batch: @batch, name: "Sujet encadré", description: "d",
                              max_booking: 4, subject: :physique)

    @eleve = creer_eleve("88000001", "Tama", batch: @batch)
    @equipe = Team.create!(name: "Équipe #{SecureRandom.hex(3)}", project: @projet, user: @eleve)
    @eleve.update!(team: @equipe)

    @referent = creer_prof("Referent", batch: @batch)
    Supervision.create!(user: @referent, project: @projet)

    @liste = @equipe.lists.first
    @carte = Card.create!(list: @liste, name: "Tâche existante", description: "d",
                          time_estimate: 2, time_unit: "jour(s)")
  end

  test "le référent voit le tableau de l'équipe" do
    sign_in @referent
    get team_path(@equipe)
    assert_response :success
    assert_match @carte.name, response.body
  end

  test "le référent crée une carte" do
    sign_in @referent
    assert_difference -> { Card.count }, 1 do
      post list_cards_path(@liste), params: { card: {
        name: "Carte du référent", description: "d", time_estimate: 1, time_unit: "jour(s)" } }
    end
    assert_redirected_to team_path(@equipe)
  end

  test "le référent modifie une carte" do
    sign_in @referent
    patch card_path(@carte), params: { card: { name: "Intitulé corrigé" } }
    assert_nil flash[:alert], "aucun refus ne doit apparaître"
    assert_equal "Intitulé corrigé", @carte.reload.name
  end

  test "le référent déplace une carte" do
    sign_in @referent
    autre = @equipe.lists.order(:position).second
    patch card_position_path, params: {
      id: @carte.id, old_list: @liste.id, new_list: autre.id, new_index: 0 }, as: :json
    assert_response :success
    assert_equal autre.id, @carte.reload.list_id
  end

  test "le référent supprime une carte" do
    sign_in @referent
    assert_difference -> { Card.count }, -1 do
      delete card_path(@carte)
    end
  end

  test "le référent valide une carte" do
    sign_in @referent
    patch card_path(@carte), params: { card: { teacher_validation: "accepted" } }
    assert_nil flash[:alert]
    assert_equal "accepted", @carte.reload.teacher_validation
  end

  test "le référent affecte un étudiant à une carte" do
    sign_in @referent
    assert_difference -> { Assignment.count }, 1 do
      post card_assignments_path(@carte), params: { assignment: { user_ids: [@eleve.id] } }
    end
  end

  test "le référent retire une affectation" do
    affectation = Assignment.create!(card: @carte, user: @eleve)
    sign_in @referent
    assert_difference -> { Assignment.count }, -1 do
      delete assignment_path(affectation)
    end
  end
end
