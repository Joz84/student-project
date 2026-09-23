# Le tableau de bilan d'un enseignant pour une UE : une colonne par séance,
# une ligne par étudiant. Sert l'affichage, l'export et l'import, pour que
# les trois parlent exactement de la même grille.
class AttendanceSheet
  attr_reader :ue, :teacher, :lessons

  def initialize(teacher:, ue:, passees_seulement: true)
    @teacher = teacher
    @ue = ue
    scope = Lesson.where(teacher: teacher, ue: ue)
    scope = scope.where("ends_at <= ?", Time.current) if passees_seulement
    @lessons = scope.order(:starts_at).to_a
  end

  def eleves
    @eleves ||= begin
      ids = lessons.flat_map { |l| l.eleves_attendus.ids }.uniq
      User.where(id: ids).order(:last_name, :first_name).to_a
    end
  end

  # Les lignes saisies à la main n'ont pas de compte : elles forment des
  # lignes supplémentaires, identifiées par leur libellé.
  def invites
    @invites ||= Attendance.where(lesson_id: lessons.map(&:id), user_id: nil)
                           .group_by { |a| [a.guest_last_name.to_s.strip.downcase,
                                            a.guest_first_name.to_s.strip.downcase,
                                            a.guest_student_number.to_s.strip] }
  end

  def pointages
    @pointages ||= Attendance.where(lesson_id: lessons.map(&:id))
                             .where.not(user_id: nil)
                             .index_by { |a| [a.lesson_id, a.user_id] }
  end

  def statut(lesson, eleve) = pointages[[lesson.id, eleve.id]]&.status

  def entete(lesson)
    "#{I18n.l(lesson.starts_at.to_date, format: '%d/%m')} #{lesson.starts_at.strftime('%H:%M')}"
  end

  def sous_entete(lesson)
    [lesson.groups.order(:label).map(&:label).join(", ").presence,
     lesson.room.presence].compact.join(" · ")
  end

  def vide? = lessons.empty?

  # Les UE pour lesquelles l'enseignant a au moins une séance.
  def self.ues_de(teacher)
    Ue.where(id: Lesson.where(teacher: teacher).where.not(ue_id: nil).select(:ue_id))
      .order(:name)
  end
end
