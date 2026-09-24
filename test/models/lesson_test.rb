require "test_helper"

# Le cœur de l'émargement : qui est attendu à une séance. La réponse se lit
# dans les groupes, jamais dans la promotion — un redoublant suit les cours
# d'une année tout en gardant son projet dans une autre.
class LessonTest < ActiveSupport::TestCase
  setup do
    @batch  = Batch.create!(title: "Promo lesson #{SecureRandom.hex(4)}")
    @ue     = Ue.create!(batch: @batch, name: "Mécanique")
    @td1    = Group.create!(ue: @ue, label: "TD-01", kind: :td)
    @td2    = Group.create!(ue: @ue, label: "TD-02", kind: :td)

    @membre = creer_eleve("10000001")
    GroupMembership.create!(user: @membre, group: @td1)
    @autre_groupe = creer_eleve("10000002")
    GroupMembership.create!(user: @autre_groupe, group: @td2)
    @sans_groupe = creer_eleve("10000003")
    @prof = creer_prof

    @seance = seance("TD-01 - Mécanique", groupes: [@td1])
  end

  test "une séance de groupe ne concerne que ses groupes" do
    assert @seance.concerne?(@membre)
    refute @seance.concerne?(@autre_groupe)
    refute @seance.concerne?(@sans_groupe)
  end

  test "ni l'enseignant ni un compte désactivé ne sont concernés" do
    refute @seance.concerne?(@prof)
    refute @seance.concerne?(nil)
    @membre.update!(drop: true)
    refute @seance.reload.concerne?(@membre)
  end

  test "un CM sans groupe concerne toute la promotion, même les sans-groupe" do
    cm = seance("CM - Mécanique", groupes: [])
    assert cm.concerne?(@membre)
    assert cm.concerne?(@sans_groupe), "un étudiant sans TD doit voir les CM"
  end

  test "un CM concerne l'auditeur d'une autre promotion inscrit dans l'UE" do
    ailleurs = Batch.create!(title: "Autre promo #{SecureRandom.hex(4)}")
    redoublant = creer_eleve("10000004", batch: ailleurs)
    cm = seance("CM - Mécanique", groupes: [])
    refute cm.concerne?(redoublant), "sans inscription dans l'UE, il n'est pas concerné"
    GroupMembership.create!(user: redoublant, group: @td2)
    assert cm.concerne?(redoublant.reload)
  end

  test "les attendus excluent les comptes désactivés et les enseignants" do
    GroupMembership.create!(user: @prof, group: @td1)
    parti = creer_eleve("10000005")
    GroupMembership.create!(user: parti, group: @td1)
    parti.update!(drop: true)

    assert_equal [@membre.id], @seance.eleves_attendus.pluck(:id).sort
  end

  test "un étudiant de plusieurs groupes de la séance n'est compté qu'une fois" do
    GroupMembership.create!(user: @membre, group: @td2)
    deux_groupes = seance("TD - Mécanique", groupes: [@td1, @td2])
    assert_equal 2, deux_groupes.eleves_attendus.count
    assert_equal 1, deux_groupes.eleves_attendus.where(id: @membre.id).count
  end

  test "le hors-liste est le reste de la promotion, sans les attendus" do
    hors = @seance.eleves_hors_liste.pluck(:id)
    refute_includes hors, @membre.id
    assert_includes hors, @autre_groupe.id
    assert_includes hors, @sans_groupe.id
    refute_includes hors, @prof.id
  end

  test "ouvrir l'appel tire un code à quatre chiffres et lève le verrou" do
    @seance.verrouiller!
    @seance.ouvrir_pointage!
    assert_match(/\A\d{4}\z/, @seance.attendance_code)
    refute @seance.verrouille?
    assert @seance.pointage_ouvert?
  end

  test "un appel validé n'est plus ouvert au pointage" do
    @seance.ouvrir_pointage!
    @seance.valider!
    refute @seance.pointage_ouvert?
    assert @seance.verrouille?, "valider fige aussi les pointages"
  end

  test "la validation reste réversible tant que le créneau court" do
    @seance.valider!
    assert @seance.rouvrable?
    refute @seance.rouvrable?(@seance.ends_at + 1.second)
  end

  test "seuls les présents sont comptés" do
    @seance.attendances.create!(user: @membre, status: :present)
    @seance.attendances.create!(user: @autre_groupe, status: :excused)
    @seance.attendances.create!(guest_last_name: "Invité", status: :present)
    assert_equal 2, @seance.presents_count
  end

  test "deux séances identiques ne coexistent pas" do
    doublon = Lesson.new(batch: @batch, ue: @ue, title: @seance.title, room: @seance.room,
                         starts_at: @seance.starts_at, ends_at: @seance.ends_at)
    refute doublon.valid?
    assert_includes doublon.errors[:starts_at].join, "déjà enregistrée"
  end

  private

  def seance(titre, groupes:, debut: 30.minutes.ago, fin: 1.hour.from_now)
    l = Lesson.create!(batch: @batch, ue: @ue, teacher: @prof, title: titre,
                       room: "C2-2", starts_at: debut, ends_at: fin)
    groupes.each { |g| LessonGroup.create!(lesson: l, group: g) }
    l
  end
end
