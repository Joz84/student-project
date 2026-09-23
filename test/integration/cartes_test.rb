require "test_helper"

class CartesTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Rails.application.env_config["action_dispatch.show_exceptions"] = :none
    @batch = Batch.create!(title: "Promo cartes #{SecureRandom.hex(4)}")
    ref = Referential.create!(title: "Réf", batch: @batch, active: true)
    bloc = SkillBlock.create!(referential: ref, title: "Bloc", position: 1)
    @skills = (1..4).map { |i| Skill.create!(skill_block: bloc, title: "Compétence #{i}", position: i) }
    projet = Project.create!(batch: @batch, name: "S", description: "d", max_booking: 4, subject: :physique)

    @a = eleve("60000001", "Ata")
    @team = Team.create!(name: "T #{SecureRandom.hex(4)}", project: projet, user: @a)
    @a.update!(team: @team)
    @b = eleve("60000002", "Bta"); @b.update!(team: @team)
    @c = eleve("60000003", "Cta"); @c.update!(team: @team)

    @carte = Card.create!(list: @team.lists.order(:position).first, name: "Souder",
                          description: "d", time_estimate: 1, time_unit: "jour(s)")
    sign_in @a
  end

  test "plusieurs collaborateurs s'ajoutent en une fois" do
    assert_difference -> { @carte.assignments.count }, 2 do
      post card_assignments_path(@carte), params: { assignment: { user_ids: [@b.id, @c.id] } }
    end
    assert_equal [@b.id, @c.id].sort, @carte.reload.users.pluck(:id).sort
  end

  test "un collaborateur déjà affecté n'est pas ajouté deux fois" do
    Assignment.create!(card: @carte, user: @b)
    assert_difference -> { @carte.assignments.count }, 1 do
      post card_assignments_path(@carte), params: { assignment: { user_ids: [@b.id, @c.id] } }
    end
  end

  test "la redirection rouvre le volet des collaborateurs sur la bonne carte" do
    post card_assignments_path(@carte), params: { assignment: { user_ids: [@b.id] } }
    assert_match(/carte=#{@carte.id}/, response.redirect_url)
    assert_match(/volet=collaborateurs/, response.redirect_url)
    assert_match(/#carte#{@carte.id}\z/, response.redirect_url)

    follow_redirect!
    assert_match "accordion-collapse collapse show", response.body,
                 "le volet doit être déplié au retour"
  end

  test "plusieurs compétences s'ajoutent en une fois" do
    assert_difference -> { @carte.card_skills.count }, 3 do
      post card_card_skills_path(@carte), params: { card_skill: { skill_ids: @skills.first(3).map(&:id) } }
    end
    assert_match(/volet=competences/, response.redirect_url)
  end

  test "une compétence déjà visée est proposée mais non cochable" do
    CardSkill.create!(card: @carte, skill: @skills.first)
    get team_path(@team, carte: @carte.id, volet: "competences")
    assert_match "choix__ligne--prise", response.body
    assert_match "disabled", response.body
  end

  test "retirer un collaborateur ramène sur le même volet" do
    a = Assignment.create!(card: @carte, user: @b)
    delete assignment_path(a)
    assert_match(/volet=collaborateurs/, response.redirect_url)
  end

  test "une soumission vide ne casse rien" do
    assert_no_difference -> { @carte.assignments.count } do
      post card_assignments_path(@carte), params: { assignment: { user_ids: [""] } }
    end
    assert_response :redirect
  end

  private

  def eleve(numero, nom)
    User.create!(email: "c-#{SecureRandom.hex(4)}@etudiant.upf.pf", first_name: "X",
                 last_name: nom, student_number: numero, batch: @batch, password: "motdepasse")
  end
end
