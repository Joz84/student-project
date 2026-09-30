module LessonsHelper
  # Les séances du jour et des prochains jours pour l'étudiant connecté.
  #
  # Ses groupes d'abord, mais aussi toute séance où un pointage le concerne :
  # un enseignant qui l'ajoute en rattrapage doit lui donner la même vue qu'aux
  # autres, sans quoi il est marqué présent sans jamais le savoir.
  def prochaines_seances(user, limite: 6)
    return Lesson.none if user.nil? || user.teacher?

    promos = [user.batch_id, *user.groups.joins(:ue).pluck("ues.batch_id")].uniq
    pointees = Attendance.where(user_id: user.id).pluck(:lesson_id)

    Lesson.where("ends_at >= ?", Time.current)
          .where("batch_id IN (:promos) OR id IN (:pointees)",
                 promos: promos, pointees: pointees.presence || [0])
          .order(:starts_at).limit(60)
          .select { |l| l.concerne?(user) || pointees.include?(l.id) }
          .first(limite)
  end

  # Les prochaines séances de l'enseignant. L'administrateur peut demander
  # celles de toute la promotion : il dépanne les collègues qui n'arrivent pas
  # à faire leur appel, et doit pour cela atteindre leur feuille.
  def seances_enseignant(user, limite: 8, toutes: false)
    return Lesson.none unless user&.teacher?

    scope = Lesson.where("ends_at >= ?", Time.current).order(:starts_at)
    scope = scope.where(teacher: user) unless toutes && user.admin
    scope.includes(:teacher).limit(toutes && user.admin ? 25 : limite)
  end

  # Le filtre n'est offert qu'à l'administrateur, et « tous » est sa vue par
  # défaut : c'est pour dépanner qu'il ouvre cette page.
  def toutes_les_seances?(user, params)
    return false unless user&.admin
    params[:cours].to_s != "miens"
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
