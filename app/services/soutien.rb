# La demande de soutien, vue d'ensemble : une ligne par UE, les étudiants qui
# se sont signalés, et le niveau que chacun a déclaré sur cette UE.
#
# Ce croisement est le cœur de la page : un étudiant qui se dit à « notion » et
# demande de l'aide n'est pas au même endroit qu'un étudiant à « application ».
# C'est lui qui permet de constituer des groupes cohérents.
class Soutien
  # Ordre de priorité : le moins avancé d'abord. Un niveau non déclaré passe
  # avant tout, faute de savoir où se situe l'étudiant.
  RANGS = { nil => 0, "notion" => 1, "initiation" => 2, "application" => 3, "maitrise" => 4 }.freeze

  Inscrit = Struct.new(:user, :niveau, :depuis, keyword_init: true) do
    def libelle = niveau ? UeAssessment::NIVEAUX[niveau] : "non déclaré"
    def rang    = RANGS.fetch(niveau, 0)
  end

  Ligne = Struct.new(:ue, :inscrits, keyword_init: true) do
    def nombre = inscrits.size
    def suivi  = ue.groups.sum { |g| g.group_memberships.size }
    # Combien d'inscrits se disent en difficulté — la part qui appelle une
    # attention immédiate.
    def fragiles = inscrits.count { |i| i.rang <= 2 }

    # La part de ceux qui suivent la matière. Sans elle, dix demandes sur une
    # option de quinze et dix sur un tronc commun de quatre-vingts se lisent
    # pareil, alors que la première est un signal bien plus fort.
    def taux
      return nil if suivi.zero?
      (100.0 * nombre / suivi).round
    end

    def par_niveau
      inscrits.group_by { |i| i.niveau }.transform_values(&:size)
    end
  end

  def initialize(batches)
    @batches = Array(batches).compact
  end

  def lignes
    @lignes ||= begin
      ues = Ue.where(batch: @batches).includes(:batch, groups: :group_memberships).to_a
      demandes = TutoringRequest.vivantes.where(ue: ues).includes(:user).group_by(&:ue_id)
      niveaux = UeAssessment.where(ue: ues).pluck(:user_id, :ue_id, :level)
                            .each_with_object({}) { |(u, e, n), h| h[[u, e]] = n }

      ues.map { |ue|
        inscrits = (demandes[ue.id] || []).map { |d|
          Inscrit.new(user: d.user, niveau: niveaux[[d.user_id, ue.id]], depuis: d.created_at)
        }.sort_by { |i| [i.rang, i.user.last_name.to_s.downcase, i.user.first_name.to_s.downcase] }
        Ligne.new(ue: ue, inscrits: inscrits)
      }.sort_by { |l| [-l.nombre, l.ue.name.to_s] }
    end
  end

  # Répartition d'ensemble par niveau déclaré, pour situer la demande : un
  # gros volume de « notion » n'appelle pas le même dispositif qu'un gros
  # volume d'« application ».
  def par_niveau
    lignes.flat_map(&:inscrits).group_by(&:niveau).transform_values(&:size)
  end

  # Les étudiants qui se signalent sur plusieurs matières : ce sont eux qu'il
  # faut regarder en premier, la difficulté y est rarement ponctuelle.
  def cumulards(seuil = 3)
    lignes.flat_map { |l| l.inscrits.map { |i| [i.user, l.ue] } }
          .group_by { |user, _| user }
          .transform_values { |paires| paires.map(&:last) }
          .select { |_, ues| ues.size >= seuil }
          .sort_by { |user, ues| [-ues.size, user.last_name.to_s.downcase] }
  end

  def total      = lignes.sum(&:nombre)
  def demandeurs = lignes.flat_map { |l| l.inscrits.map { |i| i.user.id } }.uniq.size
  def sollicitees = lignes.count { |l| l.nombre.positive? }
  def vide?      = lignes.none? { |l| l.nombre.positive? }
end
