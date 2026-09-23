require "test_helper"

class MatieresTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Rails.application.env_config["action_dispatch.show_exceptions"] = :none
    @batch = Batch.create!(title: "Promo mat #{SecureRandom.hex(4)}")
    ref = Referential.create!(title: "Réf", batch: @batch, active: true)
    bloc = SkillBlock.create!(referential: ref, title: "B", position: 1)
    Skill.create!(skill_block: bloc, title: "C", position: 1)
    projet = Project.create!(batch: @batch, name: "S", description: "d", max_booking: 4, subject: :physique)

    @ue = Ue.create!(batch: @batch, name: "Maths")
    groupe = Group.create!(ue: @ue, label: "TD-01", kind: :td)
    @eleve = User.create!(email: "m-#{SecureRandom.hex(4)}@etudiant.upf.pf", first_name: "A",
                          last_name: "B", student_number: "91000001", batch: @batch, password: "motdepasse")
    @team = Team.create!(name: "T #{SecureRandom.hex(4)}", project: projet, user: @eleve)
    @eleve.update!(team: @team)
    GroupMembership.create!(user: @eleve, group: groupe)

    debut = 2.days.ago.change(hour: 8)
    l = Lesson.create!(batch: @batch, ue: @ue, ade_uid: SecureRandom.hex(8), title: "TD-01 - Maths",
                       category: :td, starts_at: debut, ends_at: debut + 2.hours)
    LessonGroup.create!(lesson: l, group: groupe)

    @autre = User.create!(email: "m2-#{SecureRandom.hex(4)}@etudiant.upf.pf", first_name: "C",
                          last_name: "D", student_number: "91000002", batch: @batch,
                          team: @team, password: "motdepasse")
  end

  test "la page liste les matières, l'histogramme et l'échelle" do
    sign_in @eleve
    get team_matieres_path(@team)
    assert_response :success
    assert_match "Maths", response.body
    assert_match "histo__part", response.body
    UeAssessment::NIVEAUX.each_value { |libelle| assert_match libelle, response.body }
    assert_match "onglets-equipe", response.body
    assert_match "col-md-3 bg-primary", response.body
  end

  test "l'auto-évaluation se pose, se change et s'efface" do
    sign_in @eleve
    patch ue_assessment_path(@ue), params: { level: "initiation" }
    assert_equal "initiation", UeAssessment.find_by(user: @eleve, ue: @ue).level

    patch ue_assessment_path(@ue), params: { level: "maitrise" }
    assert_equal "maitrise", UeAssessment.find_by(user: @eleve, ue: @ue).level
    assert_equal 1, UeAssessment.where(user: @eleve, ue: @ue).count, "une seule ligne par matière"

    patch ue_assessment_path(@ue), params: { level: "" }
    assert_nil UeAssessment.find_by(user: @eleve, ue: @ue), "effacer revient à non évalué"
  end

  test "l'évaluation d'un étudiant lui est propre" do
    UeAssessment.create!(user: @autre, ue: @ue, level: :maitrise)
    sign_in @eleve
    patch ue_assessment_path(@ue), params: { level: "notion" }
    assert_equal "notion", UeAssessment.find_by(user: @eleve, ue: @ue).level
    assert_equal "maitrise", UeAssessment.find_by(user: @autre, ue: @ue).level,
                 "celle du camarade n'a pas bougé"
  end

  test "un étudiant sans groupe voit un message, pas une page cassée" do
    sign_in @autre
    get team_matieres_path(@team)
    assert_response :success
    assert_match(/Aucun cours/, response.body)
  end
end
