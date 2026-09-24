require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @batch = Batch.create!(title: "Promo user #{SecureRandom.hex(4)}")
  end

  # Des numéros mal saisis ont déjà dû être corrigés en production : la
  # validation est la seule barrière avant l'import de la scolarité.
  test "le numéro étudiant fait exactement huit chiffres" do
    ["1234567", "123456789", "2025ABCD", "2025 1234", ""].each do |numero|
      u = User.new(email: "x#{SecureRandom.hex(4)}@upf.pf", first_name: "A", last_name: "B",
                   student_number: numero, batch: @batch, password: "motdepasse")
      refute u.valid?, "#{numero.inspect} ne devrait pas passer"
      assert u.errors[:student_number].any?
    end
    assert creer_eleve("20251234").valid?
  end

  test "la promotion, le prénom et le nom sont exigés" do
    u = User.new(email: "y#{SecureRandom.hex(4)}@upf.pf", student_number: "20251234",
                 password: "motdepasse")
    refute u.valid?
    assert u.errors[:first_name].any?
    assert u.errors[:last_name].any?
    assert u.errors[:batch].any?
  end

  # Un compte n'est jamais effacé : les départs sont marqués, pas supprimés.
  test "la portée kept écarte les comptes désactivés" do
    actif = creer_eleve("20250001")
    parti = creer_eleve("20250002")
    parti.update!(drop: true)
    ids = User.kept.pluck(:id)
    assert_includes ids, actif.id
    refute_includes ids, parti.id
  end

  test "une couleur d'avatar est tirée à la création" do
    assert_match(/\A#[0-9A-F]{6}\z/, creer_eleve("20250003").avatar_color)
  end

  test "l'affichage du nom est normalisé" do
    u = creer_eleve("20250004", "tetuaroa")
    u.update!(first_name: "tehatuma")
    assert_equal "Tehatuma Tetuaroa", u.to_s
  end

  test "sans spécialité déclarée dans la promo, tous les projets sont éligibles" do
    2.times { |i| projet("Sujet #{i}") }
    u = creer_eleve("20250005")
    refute u.must_choose_speciality?
    assert_equal 2, u.eligible_projects.count
  end

  test "une promo à spécialités renvoie l'étudiant vers son choix" do
    Speciality.create!(batch: @batch, name: "SI", slug: "si", position: 1)
    assert creer_eleve("20250006").must_choose_speciality?
  end

  test "le classement est créé à l'inscription, un vœu par projet éligible" do
    a, b = projet("A"), projet("B")
    u = creer_eleve("20250007")
    assert_equal [a.id, b.id].sort, u.ratings.pluck(:project_id).sort
    refute u.ratings_reordered?, "un classement jamais touché n'est pas réordonné"
  end

  test "changer de spécialité réaligne le classement et rouvre la validation" do
    si = Speciality.create!(batch: @batch, name: "SI", slug: "si", position: 1,
                            project_access: :tagged_only)
    chimie = Speciality.create!(batch: @batch, name: "Chimie", slug: "chimie", position: 2,
                                project_access: :tagged_only)
    p_si, p_chimie = projet("Robot"), projet("Titrage")
    ProjectSpeciality.create!(project: p_si, speciality: si)
    ProjectSpeciality.create!(project: p_chimie, speciality: chimie)

    u = creer_eleve("20250008")
    u.update!(speciality: si)
    assert_equal [p_si.id], u.ratings.pluck(:project_id)

    u.update!(progress: :booked)
    u.update!(speciality: chimie)
    assert_equal [p_chimie.id], u.reload.ratings.pluck(:project_id),
                 "les vœux devenus inaccessibles disparaissent"
    assert u.pending?, "une offre qui bouge rouvre le classement"
  end

  test "un déplacement dans le classement se détecte" do
    projet("A"); projet("B"); projet("C")
    u = creer_eleve("20250009")
    assert u.must_rank_projects?
    u.ratings.order(:position).last.move_to_top
    assert u.reload.ratings_reordered?
  end

  test "une filière à projet unique n'a rien à classer" do
    projet("Seul")
    refute creer_eleve("20250010").must_rank_projects?
  end

  private

  def projet(nom)
    Project.create!(batch: @batch, name: nom, description: "d", max_booking: 4, subject: :physique)
  end
end
