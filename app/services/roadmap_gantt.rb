# Calcule les coordonnées d'un diagramme de Gantt pour la feuille de route
# d'une équipe : une barre par jalon, une barre plus fine par tâche datée.
#
# Tout est exprimé en pourcentage de la largeur totale, ce qui laisse la mise
# en page au navigateur et évite toute dépendance à une bibliothèque.
class RoadmapGantt
  MARGE = 7        # jours de respiration de part et d'autre
  SEUIL_MOIS = 120 # au-delà, on gradue en mois plutôt qu'en semaines

  Barre = Struct.new(:gauche, :largeur, keyword_init: true)

  attr_reader :milestones, :debut, :fin

  def initialize(milestones)
    @milestones = milestones.to_a
    @debut, @fin = bornes
  end

  def vide? = milestones.none? { |m| datee?(m) }

  def jours = (fin - debut).to_i + 1

  # Un jalon est plaçable dès qu'il porte une date ; à défaut d'une des deux,
  # on prend l'autre pour les deux bouts, ce qui donne un repère ponctuel.
  def datee?(jalon) = jalon.starts_on.present? || jalon.due_on.present?

  def barre_jalon(jalon)
    return nil unless datee?(jalon)
    barre(jalon.starts_on || jalon.due_on, jalon.due_on || jalon.starts_on)
  end

  # Une tâche commencée mais non finie court jusqu'à aujourd'hui : c'est ce
  # qui rend visible ce qui traîne.
  def barre_tache(tache)
    d = tache.begin_at&.to_date
    return nil if d.nil?
    f = tache.end_at&.to_date || (tache.terminee? ? d : Date.current)
    f = [f, d].max
    return nil if f < debut || d > fin   # hors de l'horizon : on ne dessine pas
    barre([d, debut].max, [f, fin].min)
  end

  # Ce qui n'a pas pu être placé, pour le dire plutôt que de le taire.
  def taches_hors_horizon(jalon)
    jalon.taches.select { |t| t.begin_at.present? && barre_tache(t).nil? }
  end

  def taches_sans_date(jalon)
    jalon.taches.select { |t| t.begin_at.blank? }
  end

  def position(date)
    return nil if date.nil?
    (100.0 * (date - debut) / jours).clamp(0, 100).round(3)
  end

  def aujourdhui = position(Date.current)

  def aujourdhui_visible? = Date.current.between?(debut, fin)

  # Graduations de l'axe : semaines sur un projet court, mois sinon.
  def colonnes
    par_mois = jours > SEUIL_MOIS
    bornes = []
    curseur = par_mois ? debut.beginning_of_month : debut.beginning_of_week
    while curseur <= fin
      suivant = par_mois ? curseur.next_month : curseur + 7
      bornes << {
        libelle: par_mois ? I18n.l(curseur, format: "%b %y") : "S#{curseur.cweek}",
        gauche: position([curseur, debut].max),
        largeur: position([suivant, fin + 1].min) - position([curseur, debut].max)
      }
      curseur = suivant
    end
    bornes.reject { |c| c[:largeur] <= 0 }
  end

  private

  def barre(d1, d2)
    g = position(d1)
    l = [position(d2 + 1) - g, 1.2].max   # une barre d'un jour reste visible
    Barre.new(gauche: g, largeur: [l, 100 - g].min.round(3))
  end

  # L'horizon est celui des jalons, pas celui des tâches : une carte traînant
  # une date de l'an dernier écraserait l'échelle de tout le diagramme.
  def bornes
    dates = milestones.flat_map { |m| [m.starts_on, m.due_on] }.compact
    dates << Date.current
    [dates.min - MARGE, dates.max + MARGE]
  end
end
