# Le tableau de bilan d'un enseignant pour une UE : une colonne par séance,
# une ligne par étudiant. Sert l'affichage, l'export et l'import, pour que
# les trois parlent exactement de la même grille.
class AttendanceSheet
  attr_reader :ue, :teacher, :lessons

  def initialize(teacher:, ue:, passees_seulement: true)
    @teacher = teacher
    @ue = ue
    scope = Lesson.where(teacher: teacher, ue: ue).includes(:groups)
    scope = scope.where("ends_at <= ?", Time.current) if passees_seulement
    @lessons = scope.order(:starts_at).to_a
  end

  def eleves
    @eleves ||= begin
      ids = attendus_par_seance.values.reduce(Set.new, :|)
      User.where(id: ids.to_a).order(:last_name, :first_name).to_a
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

  # Qui est attendu à quelle séance. Calculé une fois pour toute la grille :
  # une colonne de TP n'attend qu'un cinquième des lignes, et parcourir la
  # liste entière pour trouver son groupe est la première chose qui rend un
  # registre pénible à tenir.
  def attendus_par_seance
    @attendus_par_seance ||= begin
      avec_groupes, sans_groupes = lessons.partition { |l| l.group_ids.any? }

      par_groupe = GroupMembership
                   .where(group_id: avec_groupes.flat_map(&:group_ids).uniq)
                   .pluck(:group_id, :user_id)
                   .each_with_object(Hash.new { |h, k| h[k] = [] }) { |(g, u), h| h[g] << u }

      table = {}
      avec_groupes.each do |l|
        table[l.id] = l.group_ids.flat_map { |g| par_groupe[g] }.to_set
      end

      unless sans_groupes.empty?
        promos = User.kept.where(teacher: nil, batch_id: sans_groupes.map(&:batch_id).uniq)
                     .pluck(:batch_id, :id)
                     .each_with_object(Hash.new { |h, k| h[k] = [] }) { |(b, u), h| h[b] << u }
        auditeurs = ue ? GroupMembership.where(group_id: ue.group_ids).pluck(:user_id) : []
        sans_groupes.each do |l|
          table[l.id] = (promos[l.batch_id] + auditeurs).to_set
        end
      end
      table
    end
  end

  def attendu?(lesson, eleve) = attendus_par_seance[lesson.id]&.include?(eleve.id)

  def nombre_attendus(lesson) = attendus_par_seance[lesson.id]&.size.to_i

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
