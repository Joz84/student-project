require "test_helper"

# `users.team_id` ne dit que l'équipe du moment. Sans trace, changer de projet
# d'une année sur l'autre effaçait la précédente, et la promotion qu'on venait
# de quitter se retrouvait vide de ses propres équipes.
class HistoriqueEquipesTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    montrer_les_erreurs!
    @an_passe = Batch.create!(title: "Promo passée #{SecureRandom.hex(4)}")
    @cette_annee = Batch.create!(title: "Promo actuelle #{SecureRandom.hex(4)}")
    [@an_passe, @cette_annee].each do |b|
      ref = Referential.create!(title: "Réf #{b.id}", batch: b, active: true)
      bloc = SkillBlock.create!(referential: ref, title: "B", position: 1)
      Skill.create!(skill_block: bloc, title: "C", position: 1)
    end

    @vieux_projet = Project.create!(batch: @an_passe, name: "Ancien sujet", description: "d",
                                    max_booking: 1, subject: :stes)
    @projet = Project.create!(batch: @cette_annee, name: "Projet 1", description: "d",
                              max_booking: 1, subject: :stes)

    @eleve = creer_eleve("90000001", "Teata", batch: @an_passe)
    @ancienne = Team.create!(name: "Ancienne #{SecureRandom.hex(3)}", project: @vieux_projet, user: @eleve)
    @eleve.update!(team: @ancienne)

    @prof = creer_prof(batch: @cette_annee)
    Supervision.create!(user: @prof, project: @vieux_projet)
    Supervision.create!(user: @prof, project: @projet)
  end

  test "rejoindre une équipe laisse une trace" do
    assert_equal 1, @eleve.team_memberships.count
    trace = @eleve.team_memberships.first
    assert_equal @ancienne, trace.team
    assert trace.en_cours?
  end

  test "changer d'équipe ferme la précédente sans l'effacer" do
    nouvelle = Team.create!(name: "Nouvelle #{SecureRandom.hex(3)}", project: @projet, user: @eleve)
    @eleve.update!(batch: @cette_annee, team: nouvelle)

    assert_equal 2, @eleve.team_memberships.count
    ancienne = @eleve.team_memberships.find_by(team: @ancienne)
    refute ancienne.en_cours?, "elle est close"
    assert ancienne.quittee_le.present?
    assert @eleve.team_memberships.find_by(team: nouvelle).en_cours?
  end

  test "quitter une équipe sans en rejoindre une autre se note aussi" do
    @eleve.update!(team: nil)
    assert_equal 1, @eleve.team_memberships.count
    refute @eleve.team_memberships.first.en_cours?
  end

  test "revenir dans une équipe rouvre la même histoire" do
    @eleve.update!(team: nil)
    @eleve.update!(team: @ancienne)
    assert_equal 1, @eleve.team_memberships.count, "une seule ligne, pas deux"
    assert @eleve.team_memberships.first.en_cours?
  end

  test "l'équipe connaît ses membres passés" do
    @eleve.update!(batch: @cette_annee, team: nil)
    assert_empty @ancienne.users.kept
    assert_equal [@eleve.id], @ancienne.membres.map(&:id)
  end

  test "la promotion achevée garde ses équipes dans l'espace enseignant" do
    @eleve.update!(batch: @cette_annee, team: nil)

    sign_in @prof
    get teacher_batch_teams_path(@an_passe)
    assert_response :success
    assert_match @ancienne.name, response.body
    assert_match @eleve.last_name, response.body, "avec ceux qui la composaient"
  end

  test "l'étudiant relit son ancien tableau mais n'y écrit plus" do
    @eleve.update!(batch: @cette_annee, team: nil)

    sign_in @eleve
    get team_path(@ancienne)
    assert_response :success
    assert_match "Équipe d'une année achevée", response.body

    liste = @ancienne.lists.first
    assert_no_difference -> { Card.count } do
      post list_cards_path(liste), params: { card: { name: "X", description: "d",
                                                     time_estimate: 1, time_unit: "jour(s)" } }
    end
  end

  test "une équipe qu'il n'a jamais fréquentée lui reste fermée" do
    etranger = Team.create!(name: "Étrangère #{SecureRandom.hex(3)}", project: @projet, user: @prof)
    sign_in @eleve
    get team_path(etranger)
    assert_redirected_to root_path
  end

  test "un membre parti s'affiche en retrait de ceux du moment" do
    reste = creer_eleve("90000002", "Rester", batch: @an_passe, team: @ancienne)
    @eleve.update!(batch: @cette_annee, team: nil)

    sign_in @prof
    get teacher_batch_teams_path(@an_passe)
    assert_response :success

    carte = response.body[/<div class="team-card h-100">.*?Ouvrir le tableau de bord/m]
    assert carte.present?, "la carte de l'équipe doit être rendue"
    assert_match reste.last_name, carte
    assert_match @eleve.last_name, carte
    assert_match "team-card__parti", carte, "le parti porte la classe grisée"
    assert_match "avatar-sm--parti", carte
    assert_match "1 étudiant", carte, "le décompte ne retient que l'équipe du moment"
    assert_match "1 parti", carte
  end

  test "une équipe que plus personne ne compose se replie au lieu d'occuper la grille" do
    # Son unique étudiant s'en va, et son compte est désactivé : il ne reste
    # personne à montrer, mais le travail déposé doit rester atteignable.
    @eleve.update!(team: nil)
    @eleve.update!(drop: true)

    sign_in @prof
    get teacher_batch_teams_path(@an_passe)
    assert_response :success
    assert_match "Équipes sans étudiant actif", response.body
    assert_match @ancienne.name, response.body
    refute_match "team-card h-100", response.body, "aucune carte vide dans la grille"
  end

  test "un compte désactivé ne reparaît pas parmi les anciens membres" do
    @eleve.update!(drop: true, team: nil)
    assert_empty @ancienne.membres
    assert @ancienne.sans_membre?
  end
end
