# L'effectif d'une promotion, vu d'ensemble : chaque étudiant avec son groupe
# de TD, son groupe de TP, son groupe de TP informatique et son équipe de
# projet. C'est la seule page où ces quatre découpages se lisent ensemble.
#
# Ils se recoupent sans se confondre — un TD se répartit sur plusieurs TP, et
# les équipes de projet ignorent les deux. Aucun ordre unique ne les montre
# tous : la page se réorganise donc selon l'axe demandé, et chaque groupe garde
# la même teinte d'un axe à l'autre, de sorte qu'on suive un TP à l'œil en
# passant au regroupement par projet.
class Effectifs
  AXES = {
    "projet"  => "Par projet",
    "td"      => "Par TD",
    "tp"      => "Par TP",
    "tp_info" => "Par TP info",
    "aucun"   => "Liste alphabétique"
  }.freeze

  # L'intitulé du groupe absent, propre à chaque axe : « sans équipe » et
  # « sans TD » ne se corrigent pas auprès des mêmes personnes.
  SANS = {
    "projet"  => "Sans équipe",
    "td"      => "Sans groupe de TD",
    "tp"      => "Sans groupe de TP",
    "tp_info" => "Sans groupe de TP info"
  }.freeze

  # Comment nommer le découpage dans les compteurs de tête.
  NOMS = {
    "projet"  => "équipes",
    "td"      => "groupes de TD",
    "tp"      => "groupes de TP",
    "tp_info" => "groupes de TP info"
  }.freeze

  # Même palette que les UE : le site n'a qu'une langue graphique.
  TEINTES = Ue::TEINTES

  Ligne = Struct.new(:user, :td, :tp, :tp_info, :options, :team,
                     :evaluees, :demandes, :assiduite, keyword_init: true) do
    def nom = "#{user.last_name.to_s.upcase} #{user.first_name}"
    def projet = team&.project

    def libelles(axe)
      case axe
      when "td"      then td
      when "tp"      then tp
      when "tp_info" then tp_info
      when "projet"  then [team&.name].compact
      else []
      end
    end

    # La clé du regroupement. Les libellés sont joints plutôt que démultipliés :
    # un étudiant inscrit à deux TP forme son propre sous-ensemble, « TP-03 /
    # TP-04 », au lieu d'être compté deux fois — l'anomalie se voit ainsi.
    def cle(axe)
      return team&.id if axe == "projet"
      libelles(axe).join(" / ").presence
    end

    def taux_presence = assiduite&.taux
  end

  Paquet = Struct.new(:axe, :cle, :libelle, :detail, :lignes, :teinte, :rang,
                      keyword_init: true) do
    def nombre    = lignes.size
    def orphelin? = cle.nil?
    # Ni un groupe constitué, ni rien : l'équipe d'attente et les étudiants
    # sans équipe se lisent après les autres, et se traitent ensemble.
    def en_attente? = rang.to_i.positive?
  end

  def self.axe(valeur) = AXES.key?(valeur.to_s) ? valeur.to_s : nil

  def initialize(batch)
    @batch = batch
  end

  def etudiants
    @etudiants ||= User.kept.where(teacher: nil, batch: @batch)
                       .includes(team: :project)
                       .order(:last_name, :first_name).to_a
  end

  def vide? = etudiants.empty?

  def lignes
    @lignes ||= begin
      # Pas de filtre sur les UE de la promotion : un redoublant suit les
      # enseignements d'une autre année en gardant son projet ici, et ses
      # groupes réels valent mieux qu'une colonne vide.
      groupes = Hash.new { |h, k| h[k] = Hash.new { |g, j| g[j] = [] } }
      GroupMembership.where(user_id: etudiants.map(&:id)).joins(:group)
                     .pluck(:user_id, Arel.sql("groups.kind"), Arel.sql("groups.label"))
                     .each { |uid, kind, label| groupes[uid][kind] << label }

      evaluees = UeAssessment.where(user_id: etudiants.map(&:id)).where.not(level: nil)
                             .group(:user_id).count
      demandes = TutoringRequest.where(user_id: etudiants.map(&:id)).group(:user_id).count
      presences = assiduite.lignes.index_by { |l| l.user.id }

      etudiants.map do |u|
        # `pluck` rend la valeur de l'enum, pas l'entier stocké : les clés sont
        # donc les noms des genres.
        g = groupes[u.id]
        Ligne.new(
          user: u,
          td: g["td"].uniq.sort,
          tp: g["tp"].uniq.sort,
          tp_info: g["tp_info"].uniq.sort,
          options: g["option"].uniq.sort,
          team: u.team,
          evaluees: evaluees[u.id].to_i,
          demandes: demandes[u.id].to_i,
          assiduite: presences[u.id]
        )
      end
    end
  end

  def assiduite = @assiduite ||= Assiduite.new(@batch)

  # Les étudiants rangés selon l'axe demandé, chaque paquet coloré. Le groupe
  # absent passe en dernier : c'est une liste à traiter, pas un groupe.
  def paquets(axe)
    @paquets ||= {}
    @paquets[axe] ||= if axe == "aucun"
      [Paquet.new(axe: axe, cle: :tous, libelle: "Tous les étudiants",
                  detail: @batch.title, lignes: lignes, teinte: TEINTES.first)]
    else
      lignes.group_by { |l| l.cle(axe) }.map { |cle, lot|
        Paquet.new(axe: axe, cle: cle, libelle: titre(axe, cle, lot),
                   detail: detail(axe, lot), lignes: lot,
                   teinte: teinte(axe, cle), rang: rang(axe, cle, lot))
      }.sort_by { |p| [p.rang, p.libelle.to_s] }
    end
  end

  # La teinte d'un groupe, stable d'un axe à l'autre et d'une ligne à l'autre :
  # c'est elle qui tient la lecture quand le tableau n'est pas regroupé.
  def teinte(axe, cle)
    return nil if cle.nil?
    teintes(axe)[cle]
  end

  # Un axe où tout le monde est dans le même sac — ou dans aucun — n'apprend
  # rien : une promotion sans équipe s'ouvre donc sur ses TD.
  def axe_par_defaut
    AXES.keys.find { |a| a != "aucun" && paquets(a).count { |p| !p.orphelin? } > 1 } || "aucun"
  end

  def sans_groupe(axe) = paquets(axe).find(&:orphelin?)&.nombre.to_i
  def groupes(axe)     = paquets(axe).count { |p| !p.orphelin? }

  private

  def teintes(axe)
    @teintes ||= {}
    @teintes[axe] ||= begin
      cles = lignes.filter_map { |l| l.cle(axe) }.uniq
                   .sort_by { |cle| libelle_brut(axe, cle).to_s }
      cles.each_with_index.to_h { |cle, i| [cle, TEINTES[i % TEINTES.size]] }
    end
  end

  def libelle_brut(axe, cle)
    axe == "projet" ? equipes[cle]&.name : cle
  end

  def equipes = @equipes ||= lignes.filter_map(&:team).uniq.index_by(&:id)

  def titre(axe, cle, lot)
    return SANS.fetch(axe, "Non renseigné") if cle.nil?
    axe == "projet" ? lot.first.team.name : cle
  end

  # Le projet de l'équipe, quand il apprend quelque chose : les équipes portent
  # presque toutes le nom de leur projet, et le répéter en sous-titre mettait
  # deux fois la même phrase sur la même ligne.
  def detail(axe, lot)
    return nil unless axe == "projet" && lot.first.team
    nom = lot.first.projet&.name
    return "aucun projet attribué" if nom.nil?
    nom == lot.first.team.name ? nil : nom
  end

  # Une équipe sans projet — l'équipe d'attente — ne travaille encore sur rien :
  # elle se range après les équipes constituées, et avant ceux qui n'ont aucune
  # équipe du tout.
  def rang(axe, cle, lot)
    return 2 if cle.nil?
    return 1 if axe == "projet" && lot.first.projet.nil?
    0
  end
end
