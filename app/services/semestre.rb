# Le semestre d'un étudiant : ses matières, le volume horaire de chacune, ce
# qui est déjà passé, et la répartition semaine par semaine.
#
# Les heures sont celles de son emploi du temps réel — ses groupes de TD et de
# TP, plus les CM de ses UE — et non un maquettage théorique.
class Semestre
  attr_reader :user, :debut, :fin

  def initialize(user, reference: Date.current)
    @user = user
    @debut, @fin = bornes(reference)
  end

  # Août à janvier, puis février à juillet : le découpage universitaire usuel.
  def self.bornes_du_semestre(date)
    if date.month >= 8
      [Date.new(date.year, 8, 1), Date.new(date.year + 1, 1, 31)]
    elsif date.month <= 1
      [Date.new(date.year - 1, 8, 1), Date.new(date.year, 1, 31)]
    else
      [Date.new(date.year, 2, 1), Date.new(date.year, 7, 31)]
    end
  end

  def libelle = "#{I18n.l(debut, format: '%B %Y')} – #{I18n.l(fin, format: '%B %Y')}".gsub(/\b\w/) { $&.upcase }

  # Les UE que l'étudiant suit réellement, c'est-à-dire celles où il a un
  # groupe. `Lesson#concerne?` est plus large à dessein — un CM y concerne
  # toute la promotion, pour l'émargement — mais une matière d'option qu'on ne
  # suit pas n'a rien à faire dans son relevé d'heures.
  def ues_suivies
    @ues_suivies ||= Ue.where(id: user.groups.select(:ue_id)).index_by(&:id)
  end

  def seances
    @seances ||= begin
      fenetre = debut.beginning_of_day..fin.end_of_day
      Lesson.where(batch_id: user.batch_id, starts_at: fenetre)
            .where(ue_id: ues_suivies.keys)
            .includes(:ue, :groups).to_a
            .select { |l| l.groups.empty? || (l.group_ids & user.group_ids).any? }
    end
  end

  def vide? = seances.empty?

  def matieres
    @matieres ||= seances.group_by(&:ue).filter_map { |ue, ls|
      next if ue.nil?
      Matiere.new(ue: ue, seances: ls)
    }.sort_by { |m| -m.heures }
  end

  def heures_totales = matieres.sum(&:heures).round(1)
  def heures_faites  = matieres.sum(&:heures_faites).round(1)

  def avancement
    return 0 if heures_totales.zero?
    (100.0 * heures_faites / heures_totales).round
  end

  # Une entrée par semaine du semestre où il y a cours, avec le détail par UE.
  def semaines
    @semaines ||= begin
      groupes = seances.group_by { |l| l.starts_at.to_date.beginning_of_week }
      groupes.keys.min.upto(groupes.keys.max).select { |d| d == d.beginning_of_week }.map do |lundi|
        ls = groupes[lundi] || []
        Semaine.new(
          lundi: lundi,
          numero: lundi.cweek,
          parts: ls.group_by(&:ue).filter_map { |ue, sous|
            next if ue.nil?
            { ue: ue, heures: duree(sous) }
          }.sort_by { |p| -p[:heures] },
          total: duree(ls.select(&:ue))
        )
      end
    end
  end

  def heures_max_semaine = semaines.map(&:total).max.to_f

  private

  def bornes(reference) = self.class.bornes_du_semestre(reference)

  def duree(ls) = ls.sum { |l| (l.ends_at - l.starts_at) / 3600.0 }.round(2)

  Matiere = Struct.new(:ue, :seances, keyword_init: true) do
    def heures = seances.sum { |l| (l.ends_at - l.starts_at) / 3600.0 }.round(1)

    def heures_faites
      seances.select { |l| l.ends_at <= Time.current }
             .sum { |l| (l.ends_at - l.starts_at) / 3600.0 }.round(1)
    end

    def pourcentage
      return 0 if heures.zero?
      (100.0 * heures_faites / heures).round
    end

    def nombre_seances = seances.size
    def teinte = ue.teinte
  end

  Semaine = Struct.new(:lundi, :numero, :parts, :total, keyword_init: true) do
    def passee? = lundi.end_of_week < Date.current
    def courante? = Date.current.between?(lundi, lundi.end_of_week)
  end
end
