# L'emploi du temps d'un étudiant sur une semaine, prêt à être posé sur une
# grille : chaque séance connaît sa colonne (le jour) et sa position verticale
# (l'heure), exprimée en pourcentage de la plage affichée.
class Calendrier
  DEBUT_PAR_DEFAUT = 7   # heures
  FIN_PAR_DEFAUT   = 18

  attr_reader :user, :lundi

  def initialize(user, date: Date.current)
    @user = user
    @lundi = date.to_date.beginning_of_week
  end

  def semaine_precedente = lundi - 7
  def semaine_suivante   = lundi + 7
  def contient_aujourdhui? = Date.current.between?(lundi, lundi + 6)

  def libelle
    fin = lundi + 6
    if lundi.month == fin.month
      "#{lundi.day} – #{I18n.l(fin, format: '%-d %B %Y')}"
    else
      "#{I18n.l(lundi, format: '%-d %b')} – #{I18n.l(fin, format: '%-d %b %Y')}"
    end
  end

  # Ce que l'étudiant doit suivre : les séances de ses groupes, les CM des UE
  # qu'il suit, et les événements sans matière — réunions, examens — qui
  # concernent la promotion.
  def seances
    @seances ||= begin
      fenetre = lundi.beginning_of_day..(lundi + 6).end_of_day
      suivies = Ue.where(id: user.groups.select(:ue_id)).ids
      Lesson.where(batch_id: user.batch_id, starts_at: fenetre)
            .includes(:ue, :groups).order(:starts_at).to_a
            .select { |l| retenue?(l, suivies) }
    end
  end

  def vide? = seances.empty?

  def jours
    @jours ||= begin
      utiles = seances.map { |l| l.starts_at.to_date }.uniq
      dernier = [(utiles.max || lundi + 4), lundi + 4].max   # du lundi au vendredi au minimum
      (lundi..dernier).to_a
    end
  end

  def seances_du(jour) = seances.select { |l| l.starts_at.to_date == jour }

  # Plage horaire réellement occupée, arrondie à l'heure, avec un repli si la
  # semaine est vide.
  def plage
    @plage ||= begin
      return [DEBUT_PAR_DEFAUT, FIN_PAR_DEFAUT] if seances.empty?
      debut = seances.map { |l| l.starts_at.hour }.min
      fin = seances.map { |l| (l.ends_at.min.zero? ? l.ends_at.hour : l.ends_at.hour + 1) }.max
      [[debut, DEBUT_PAR_DEFAUT].min, [fin, FIN_PAR_DEFAUT].max]
    end
  end

  def heures = (plage.first...plage.last).to_a

  def position(lesson)
    minutes_totales = (plage.last - plage.first) * 60.0
    depuis = (lesson.starts_at.hour * 60 + lesson.starts_at.min) - plage.first * 60
    duree = (lesson.ends_at - lesson.starts_at) / 60.0
    { haut: (100.0 * depuis / minutes_totales).round(3),
      hauteur: [(100.0 * duree / minutes_totales), 2.5].max.round(3) }
  end

  def teinte(lesson) = lesson.ue&.teinte || "#8A96A3"

  private

  def retenue?(lesson, suivies)
    return false unless lesson.concerne?(user)
    lesson.ue_id.nil? || suivies.include?(lesson.ue_id)
  end
end
