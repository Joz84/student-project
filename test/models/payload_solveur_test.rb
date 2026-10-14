require "test_helper"

# Le payload est le contrat entre Rails et le solveur Python. Ce test fige
# ce qu'il transmet : sans le sujet des projets, la contrainte « au moins
# deux projets de chaque catégorie » n'a rien à quoi s'accrocher.
class PayloadSolveurTest < ActiveSupport::TestCase
  setup do
    @batch = Batch.create!(title: "Promo payload #{SecureRandom.hex(4)}")
    ref = Referential.create!(title: "Réf", batch: @batch, active: true)
    bloc = SkillBlock.create!(referential: ref, title: "B", position: 1)
    Skill.create!(skill_block: bloc, title: "C", position: 1)
    @p1 = Project.create!(batch: @batch, name: "Un", description: "d",
                          max_booking: 1, subject: :clustering)
    @p2 = Project.create!(batch: @batch, name: "Deux", description: "d",
                          max_booking: 1, subject: :deep_learning)
  end

  test "chaque projet annonce son sujet et sa capacité" do
    creer_eleve("84000001", "Atiu", batch: @batch)
    payload = @batch.solver_payload
    assert_equal({ max_booking: 1, subject: "clustering" }, payload[:projects][@p1.slug])
    assert_equal({ max_booking: 1, subject: "deep_learning" }, payload[:projects][@p2.slug])
  end

  test "l'export restreint aux validés ignore les autres" do
    valide = creer_eleve("84000002", "Validant", batch: @batch)
    valide.ratings.each_with_index { |r, i| r.update!(position: 2 - i) }
    valide.update!(progress: :booked)
    creer_eleve("84000003", "Traine", batch: @batch)

    complet = @batch.solver_payload
    assert_equal 2, complet[:students].size

    restreint = @batch.solver_payload(@batch.users.kept.where(teacher: nil).booked)
    assert_equal [valide.slug], restreint[:students].keys
    assert restreint[:scores].keys.all? { |k| k.include?(valide.slug) },
           "aucune note ne doit concerner un étudiant non validé"
  end
end
