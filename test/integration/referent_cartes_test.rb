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

  test "une carte évaluée reste modifiable par le référent, figée pour l'étudiant" do
    @carte.update!(teacher_validation: "accepted")

    sign_in @referent
    get team_path(@equipe)
    assert_match "Modifier la tâche", response.body,
                 "l'enseignant doit pouvoir corriger ce qu'il vient d'évaluer"
    sign_out :user

    sign_in @eleve
    get team_path(@equipe)
    refute_match "Modifier la tâche", response.body,
                 "une tâche évaluée ne se modifie plus côté étudiant"
  end

  test "après modification, le panneau de la carte se rouvre sur place" do
    sign_in @referent
    patch card_path(@carte), params: { volet: "modifier", card: { name: "Reformulée" } }
    assert_redirected_to team_path(@equipe, carte: @carte.id, volet: "modifier",
                                   anchor: "carte#{@carte.id}")
    assert_equal "Tâche modifiée.", flash[:notice]

    follow_redirect!
    assert_response :success
    assert_match "Reformulée", response.body
    # L'accordéon doit être déplié, sinon la modification paraît perdue.
    assert_match "collapseThree#{@carte.id}\" class=\"accordion-collapse collapse p-2 show",
                 response.body
  end

  test "une modification refusée explique pourquoi et ne prétend pas avoir réussi" do
    sign_in @referent
    patch card_path(@carte), params: { volet: "modifier", card: { name: "" } }
    assert_nil flash[:notice], "aucun message de succès sur un échec"
    assert_match(/Name|Nom/, flash[:alert].to_s)
    assert_equal "Tâche existante", @carte.reload.name
  end
end
