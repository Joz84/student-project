# Rattache les étudiants aux groupes de TD et de TP, UE par UE, d'après le
# classeur de la scolarité. Les groupes eux-mêmes viennent d'ADE : on ne crée
# rien ici, un libellé sans correspondance est signalé plutôt qu'inventé,
# faute de quoi l'étudiant serait inscrit à un groupe sans aucune séance.
class GroupMembershipsImporter
  # Les onglets du classeur ne portent pas l'intitulé exact des UE d'ADE.
  UES = {
    "1.1 Calcul num et algéb"         => "Calcul numérique et algébrique",
    "1.2 Calcul fonctionnel"          => "Calcul fonctionnel",
    "1.3 Mécanique du solide"         => "Mécanique du solide",
    "1.4 Structure de la matière"     => "Structure de la matière",
    "1.6.1 CNB PIX"                   => "CNB PIX",
    "1.6.2 Conception 3D"             => "Outils de conception 3D",
    "1.7 Prog impérative"             => "Programmation impérative",
    "1.9 Comp pro Chimie"             => "Découverte des compétences pro chimie",
    "1.10 Comp pro Mesures physiques" => "Découverte des compétences pro mesures physiques",
    "1.11Comp pro Systèmes physiques" => "Découverte des compétences pro Syst physique",
    "1.12 PROJET"                     => "Projet (REH)"
  }.freeze

  # « TD1 » -> « TD-01 », « TP03INFO » -> « TP-03INFO »
  GROUPE = /\A(TD|TP)\s*-?\s*0*(\d{1,2})\s*(INFO)?\z/i

  Resultat = Struct.new(:creees, :existantes, :etudiants, :ues,
                        :sans_etudiant, :sans_ue, :sans_groupe, :ignores,
                        keyword_init: true) do
    def to_s
      "#{creees} appartenances créées, #{existantes} déjà présentes · " \
      "#{etudiants} étudiants sur #{ues} UE"
    end
  end

  def initialize(batch, lignes)
    @batch = batch
    @lignes = lignes
  end

  def run(dry_run: true)
    creees = existantes = 0
    sans_etudiant = Hash.new { |h, k| h[k] = [] }
    sans_ue = Set.new
    sans_groupe = Hash.new { |h, k| h[k] = Set.new }
    ignores = Hash.new(0)
    etudiants = Set.new
    ues = Set.new

    ActiveRecord::Base.transaction do
      @lignes.each do |l|
        feuille, num, libelle = l["feuille"], l["num"].to_s.strip, l["libelle"].to_s.strip

        labels = libelle.split("/").map(&:strip).select { |x| x =~ GROUPE }
        if labels.empty?
          ignores[libelle] += 1
          next
        end

        nom_ue = UES[feuille]
        if nom_ue.nil?
          sans_ue << feuille
          next
        end
        ue = Ue.find_by(batch: @batch, name: nom_ue)
        if ue.nil?
          sans_ue << "#{feuille} -> #{nom_ue} (absente d'ADE)"
          next
        end
        ues << ue.id

        eleve = etudiant(num)
        if eleve.nil?
          sans_etudiant[num] << feuille
          next
        end
        etudiants << eleve.id

        labels.each do |label|
          groupe = ue.groups.find_by(label: normaliser(label))
          if groupe.nil?
            sans_groupe[ue.name] << label
            next
          end
          if GroupMembership.exists?(user: eleve, group: groupe)
            existantes += 1
          else
            GroupMembership.create!(user: eleve, group: groupe)
            creees += 1
          end
        end
      end
      raise ActiveRecord::Rollback if dry_run
    end

    Resultat.new(creees: creees, existantes: existantes, etudiants: etudiants.size,
                 ues: ues.size, sans_etudiant: sans_etudiant, sans_ue: sans_ue.to_a,
                 sans_groupe: sans_groupe.transform_values(&:to_a), ignores: ignores)
  end

  private

  def normaliser(label)
    t, n, info = label.match(GROUPE).captures
    "#{t.upcase}-#{n.rjust(2, '0')}#{'INFO' if info}"
  end

  # Le numéro fait foi ; on n'apparie pas sur le nom, trop d'homonymes et de
  # coquilles dans les exports de la scolarité.
  def etudiant(num)
    @index ||= User.kept.where(teacher: nil).index_by { |u| u.student_number.to_s.strip }
    @index[num]
  end
end
