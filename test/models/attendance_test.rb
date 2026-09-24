require "test_helper"

class AttendanceTest < ActiveSupport::TestCase
  setup do
    @batch = Batch.create!(title: "Promo pointage #{SecureRandom.hex(4)}")
    @ue = Ue.create!(batch: @batch, name: "Chimie")
    @eleve = creer_eleve("20000001", "Tetua")
    @seance = Lesson.create!(batch: @batch, ue: @ue, title: "TD-01 - Chimie",
                             starts_at: 1.hour.ago, ends_at: 1.hour.from_now)
  end

  # Le piège qui a coûté une régression : sans préfixe, `present?` d'ActiveRecord
  # se retrouve masqué et un pointage « absent » répond « je n'existe pas ».
  test "l'état ne masque pas la question de l'existence" do
    absent = @seance.attendances.create!(user: @eleve, status: :absent)
    assert absent.present?, "un objet absent existe quand même"
    assert absent.statut_absent?
    refute absent.statut_present?
  end

  test "les quatre états du pointage portent un libellé" do
    assert_equal %w[absent present excused retard].sort, Attendance.statuses.keys.sort
    Attendance.statuses.each_key do |etat|
      assert Attendance::LIBELLES[etat].present?, "#{etat} doit avoir un libellé"
    end
  end

  test "un étudiant n'est pointé qu'une fois par séance" do
    @seance.attendances.create!(user: @eleve, status: :present)
    doublon = @seance.attendances.new(user: @eleve, status: :absent)
    refute doublon.valid?
  end

  test "plusieurs invités cohabitent sur la même séance" do
    a = @seance.attendances.create!(guest_last_name: "Un", status: :present)
    b = @seance.attendances.create!(guest_last_name: "Deux", status: :present)
    assert a.invite?
    assert b.persisted?, "l'unicité ne vise que les comptes, pas les saisies libres"
  end

  test "un invité sans aucun nom reste acceptable" do
    # Aucune validation côté modèle : l'enseignant devant sa classe doit
    # pouvoir écrire ce dont il dispose. Le contrôleur, lui, exige un champ.
    ligne = @seance.attendances.create!(status: :present)
    assert ligne.persisted?
    assert_equal "Sans nom", ligne.nom_complet
    assert_nil ligne.numero
  end

  test "le nom affiché vient du compte quand il y en a un" do
    ligne = @seance.attendances.create!(user: @eleve, status: :present)
    assert_equal "Test Tetua", ligne.nom_complet
    assert_equal "20000001", ligne.numero
    refute ligne.invite?
  end

  test "le nom d'un invité se recompose de ce qui a été saisi" do
    ligne = @seance.attendances.create!(guest_first_name: "Kalei", guest_student_number: "20260001",
                                        status: :present)
    assert_equal "Kalei", ligne.nom_complet
    assert_equal "20260001", ligne.numero
  end

  test "le pointage retient qui l'a déclaré" do
    par_eleve = @seance.attendances.create!(user: @eleve, status: :present, declared_by: :student)
    assert par_eleve.by_student?
    refute par_eleve.by_teacher?
  end
end
