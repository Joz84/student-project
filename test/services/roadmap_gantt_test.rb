require "test_helper"

class RoadmapGanttTest < ActiveSupport::TestCase
  setup do
    @batch = Batch.create!(title: "Promo gantt #{SecureRandom.hex(4)}")
    projet = Project.create!(batch: @batch, name: "S", description: "d", max_booking: 4, subject: :physique)
    eleve = User.create!(email: "g-#{SecureRandom.hex(4)}@etudiant.upf.pf", first_name: "A",
                         last_name: "B", student_number: "80000001", batch: @batch, password: "motdepasse")
    @team = Team.create!(name: "T #{SecureRandom.hex(4)}", project: projet, user: eleve)
    @liste = @team.lists.order(:position).first
  end

  test "sans jalon daté le diagramme se déclare vide" do
    @team.milestones.create!(name: "Sans date")
    assert RoadmapGantt.new(@team.milestones).vide?
  end

  test "l'horizon vient des jalons, pas des tâches" do
    jalon = @team.milestones.create!(name: "J", starts_on: Date.current, due_on: Date.current + 30)
    # Une tâche traînant une date de l'an dernier ne doit pas écraser l'échelle.
    carte("vieille", debut: Date.current - 400).update!(milestone: jalon)
    assert_operator RoadmapGantt.new(@team.milestones).jours, :<, 60
  end

  test "une tâche achevée avant la période n'est pas dessinée" do
    jalon = @team.milestones.create!(name: "J", starts_on: Date.current, due_on: Date.current + 30)
    vieille = carte("close l'an dernier", debut: Date.current - 400)
    vieille.update!(milestone: jalon, end_at: (Date.current - 380).to_time)
    g = RoadmapGantt.new(@team.milestones)
    assert_nil g.barre_tache(vieille)
    assert_equal 1, g.taches_hors_horizon(jalon).size
  end

  test "une tâche ancienne mais toujours en cours est rognée à gauche" do
    # Elle court jusqu'à aujourd'hui : elle chevauche bien la période, et son
    # ancienneté se lit au fait qu'elle part du bord.
    jalon = @team.milestones.create!(name: "J", starts_on: Date.current, due_on: Date.current + 30)
    vieille = carte("jamais finie", debut: Date.current - 400)
    vieille.update!(milestone: jalon)
    b = RoadmapGantt.new(@team.milestones).barre_tache(vieille)
    refute_nil b
    assert_equal 0.0, b.gauche
  end

  test "les barres restent dans les bornes" do
    jalon = @team.milestones.create!(name: "J", starts_on: Date.current, due_on: Date.current + 20)
    g = RoadmapGantt.new(@team.milestones)
    b = g.barre_jalon(jalon)
    assert_operator b.gauche, :>=, 0
    assert_operator b.gauche + b.largeur, :<=, 100.001
    assert_operator b.largeur, :>, 0
  end

  test "un jalon d'un seul jour reste visible" do
    jalon = @team.milestones.create!(name: "Ponctuel", due_on: Date.current + 5)
    b = RoadmapGantt.new(@team.milestones).barre_jalon(jalon)
    assert_operator b.largeur, :>=, 1.2, "une barre d'un jour garde une largeur minimale"
  end

  test "une tâche commencée et non finie court jusqu'à aujourd'hui" do
    jalon = @team.milestones.create!(name: "J", starts_on: Date.current - 30, due_on: Date.current + 30)
    tache = carte("en cours", debut: Date.current - 10)
    tache.update!(milestone: jalon)
    g = RoadmapGantt.new(@team.milestones)
    b = g.barre_tache(tache)
    assert_in_delta g.position(Date.current), b.gauche + b.largeur, 2.0
  end

  test "les graduations couvrent la période sans déborder" do
    @team.milestones.create!(name: "J", starts_on: Date.current, due_on: Date.current + 200)
    g = RoadmapGantt.new(@team.milestones)
    assert g.colonnes.any?
    assert_operator g.colonnes.last[:gauche] + g.colonnes.last[:largeur], :<=, 100.001
    assert g.colonnes.all? { |c| c[:largeur] > 0 }
  end

  private

  def carte(nom, debut:)
    Card.create!(list: @liste, name: nom, description: "d", time_estimate: 1,
                 time_unit: "jour(s)", begin_at: debut.to_time)
  end
end
