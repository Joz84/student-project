module LessonsHelper
  # Les séances du jour et des prochains jours pour l'étudiant connecté.
  def prochaines_seances(user, limite: 6)
    return Lesson.none if user.nil? || user.teacher?
    Lesson.where(batch_id: [user.batch_id, *user.groups.joins(:ue).pluck("ues.batch_id")].uniq)
          .where("ends_at >= ?", Time.current)
          .order(:starts_at).limit(60)
          .select { |l| l.concerne?(user) }
          .first(limite)
  end

  def seances_enseignant(user, limite: 8)
    return Lesson.none unless user&.teacher?
    Lesson.where(teacher: user).where("ends_at >= ?", Time.current)
          .order(:starts_at).limit(limite)
  end

  def creneau(lesson)
    fin = lesson.ends_at.strftime("%H:%M")
    if lesson.starts_at.to_date == Date.current
      "aujourd'hui #{lesson.starts_at.strftime('%H:%M')} – #{fin}"
    else
      I18n.l(lesson.starts_at, format: "%a %d/%m %H:%M").capitalize + " – #{fin}"
    end
  end
end
