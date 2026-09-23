require "test_helper"

class SemestreTest < ActiveSupport::TestCase
  setup do
    @batch = Batch.create!(title: "Promo sem #{SecureRandom.hex(4)}")
    @maths = Ue.create!(batch: @batch, name: "Maths")
    @physique = Ue.create!(batch: @batch, name: "Physique")
    @option = Ue.create!(batch: @batch, name: "Option non suivie")
    @g_maths = Group.create!(ue: @maths, label: "TD-01", kind: :td)
    @g_phys = Group.create!(ue: @physique, label: "TP-01", kind: :tp)
    Group.create!(ue: @option, label: "TD-01", kind: :td)

    @eleve = User.create!(email: "s-#{SecureRandom.hex(4)}@etudiant.upf.pf", first_name: "A",
                          last_name: "B", student_number: "90000001", batch: @batch,
                          password: "motdepasse")
    GroupMembership.create!(user: @eleve, group: @g_maths)
    GroupMembership.create!(user: @eleve, group: @g_phys)
  end

  test "le semestre court d'août à janvier, puis de février à juillet" do
    assert_equal [Date.new(2026, 8, 1), Date.new(2027, 1, 31)],
                 Semestre.bornes_du_semestre(Date.new(2026, 9, 15))
    assert_equal [Date.new(2026, 8, 1), Date.new(2027, 1, 31)],
                 Semestre.bornes_du_semestre(Date.new(2027, 1, 10))
    assert_equal [Date.new(2027, 2, 1), Date.new(2027, 7, 31)],
                 Semestre.bornes_du_semestre(Date.new(2027, 3, 3))
  end

  test "ne retient que les matières réellement suivies" do
    seance(@maths, @g_maths, 2.days.ago, 2)
    seance(@physique, @g_phys, 1.day.ago, 3)
    # Un CM de l'option : il concerne la promotion pour l'émargement, mais
    # l'étudiant ne suit pas cette matière, elle ne doit pas être comptée.
    seance(@option, nil, 1.day.ago, 4)

    s = Semestre.new(@eleve, reference: Date.current)
    assert_equal ["Physique", "Maths"], s.matieres.map { |m| m.ue.name }
    assert_equal 5.0, s.heures_totales
  end

  test "un CM d'une matière suivie compte, un TD d'un autre groupe non" do
    seance(@maths, nil, 2.days.ago, 2)                    # CM de maths : compte
    autre = Group.create!(ue: @maths, label: "TD-02", kind: :td)
    seance(@maths, autre, 2.days.ago, 3)                  # TD d'un autre groupe : non
    s = Semestre.new(@eleve)
    assert_equal 2.0, s.heures_totales
  end

  test "les heures faites sont celles des séances terminées" do
    seance(@maths, @g_maths, 3.days.ago, 2)
    seance(@maths, @g_maths, 3.days.from_now, 6)
    s = Semestre.new(@eleve)
    assert_equal 8.0, s.heures_totales
    assert_equal 2.0, s.heures_faites
    assert_equal 25, s.avancement
    assert_equal 25, s.matieres.first.pourcentage
  end

  test "les semaines cumulent les heures par matière" do
    lundi = Date.current.beginning_of_week
    seance(@maths, @g_maths, lundi + 1, 2)
    seance(@physique, @g_phys, lundi + 2, 3)
    s = Semestre.new(@eleve)
    semaine = s.semaines.find { |w| w.lundi == lundi }
    assert_equal 5.0, semaine.total
    assert_equal 2, semaine.parts.size
    assert semaine.courante?
    assert_equal 5.0, s.heures_max_semaine
  end

  test "chaque UE d'une promotion a sa propre teinte" do
    teintes = @batch.ues.map(&:teinte)
    assert_equal teintes.size, teintes.uniq.size
  end

  private

  def seance(ue, groupe, quand, heures)
    debut = quand.to_time.change(hour: 8)
    l = Lesson.create!(batch: @batch, ue: ue, ade_uid: SecureRandom.hex(8),
                       title: "#{groupe&.label || 'CM'} - #{ue.name}", category: groupe ? :td : :cm,
                       starts_at: debut, ends_at: debut + heures.hours)
    LessonGroup.create!(lesson: l, group: groupe) if groupe
    l
  end
end
