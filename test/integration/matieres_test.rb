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

    # Une séance d'aujourd'hui, déjà terminée : elle tombe donc dans la
    # semaine en cours, que le graphique doit mettre en avant.
    l = Lesson.create!(batch: @batch, ue: @ue, ade_uid: SecureRandom.hex(8), title: "TD-01 - Maths",
                       category: :td, starts_at: 3.hours.ago, ends_at: 1.hour.ago)
    LessonGroup.create!(lesson: l, group: groupe)

    @autre = User.create!(email: "m2-#{SecureRandom.hex(4)}@etudiant.upf.pf", first_name: "C",
                          last_name: "D", student_number: "91000002", batch: @batch,
                          team: @team, password: "motdepasse")
  end

  test "la page liste les matières, l'histogramme et l'échelle" do
    sign_in @eleve
    get matieres_path
    assert_response :success
    assert_match "Maths", response.body
    assert_match "histo__part", response.body
    UeAssessment::NIVEAUX.each_value { |libelle| assert_match libelle, response.body }
    assert_match "histo__colonne--courante", response.body, "la semaine en cours est marquée"
    assert_match "cette semaine", response.body
  end

  test "l'accueil mène aux matières, à côté de l'espace projet" do
    sign_in @eleve
    get root_path
    assert_response :success
    assert_match matieres_path, response.body
    assert_match project_router_path, response.body
  end

  test "le statut global se déduit des niveaux déclarés" do
    sign_in @eleve
    get matieres_path
    assert_match "Non évalué", response.body

    patch ue_assessment_path(@ue), params: { level: "application" }
    get matieres_path
    assert_match "En consolidation", response.body
    # Le gabarit coupe la ligne entre « matière » et « évaluée ».
    assert_match(/1 matière\s+évaluée sur 1/, response.body)
    assert_match "3.0/4", response.body.gsub(/\s+/, " ")
  end

  test "le travail personnel se déclare et se compare à l'attendu" do
    sign_in @eleve
    # 2 h de cours déjà passées : 1 h à la maison fait 50 %.
    patch ue_assessment_path(@ue), params: { home_hours: "1" }
    assert_equal 1.0, UeAssessment.find_by(user: @eleve, ue: @ue).home_hours

    get matieres_path
    assert_match "50 %", response.body
    assert_match "maison__taux--faible", response.body, "en deçà de l'attendu, c'est signalé"

    patch ue_assessment_path(@ue), params: { home_hours: "2" }
    get matieres_path
    refute_match "maison__taux--faible", response.body
  end

  test "déclarer des heures sans niveau reste possible, et l'inverse" do
    sign_in @eleve
    patch ue_assessment_path(@ue), params: { home_hours: "3" }
    evaluation = UeAssessment.find_by(user: @eleve, ue: @ue)
    assert_nil evaluation.level
    assert_equal 3.0, evaluation.home_hours

    # Effacer le niveau ne doit pas emporter les heures.
    patch ue_assessment_path(@ue), params: { level: "notion" }
    patch ue_assessment_path(@ue), params: { level: "" }
    assert_equal 3.0, UeAssessment.find_by(user: @eleve, ue: @ue).home_hours

    patch ue_assessment_path(@ue), params: { home_hours: "0" }
    assert_nil UeAssessment.find_by(user: @eleve, ue: @ue), "plus rien à retenir"
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
    get matieres_path
    assert_response :success
    assert_match(/Aucun cours/, response.body)
  end
end
