# La maquette officielle de la Licence 1 SPI, telle que la scolarité la
# numérote. ADE nomme les enseignements autrement — « SPI : Géophysique » pour
# 1.5.b, « CNB PIX » pour 1.6.1 — et l'import crée ses UE au fil de l'eau, sur
# ces intitulés-là. Ce tableau donne le code officiel à chacune, et complète ce
# qu'ADE n'a pas encore publié, pour qu'un enseignant choisisse son cours dans
# la liste qu'il connaît.
class MaquetteL1
  # [code, intitulé officiel, intitulés ADE rapprochés]
  ENTREES = [
    ["1.1",   "Calcul numérique et algébrique",                                 ["Calcul numérique et algébrique"]],
    ["1.2",   "Calcul fonctionnel",                                             ["Calcul fonctionnel"]],
    ["1.3",   "Mécanique du solide",                                            ["Mécanique du solide"]],
    ["1.4",   "Structure de la matière",                                        ["Structure de la matière"]],
    ["1.5.a", "Arithmétique",                                                   ["Mathématiques : Arithmétique"]],
    ["1.5.b", "Sciences pour l'ingénieur : Méthodes chimiques",                 ["SPI : Méthodes chimiques"]],
    ["1.5.b", "Sciences pour l'ingénieur : Géophysique",                        ["SPI : Géophysique"]],
    ["1.6.1", "Compétences numériques, bureautique et certification PIX",       ["CNB PIX"]],
    ["1.6.1", "Certification PIX",                                              ["Certification PIX"]],
    ["1.6.1", "CC2 et épreuve terminale CNB PIX",                               ["CC2+ET CNB PIX"]],
    ["1.6.2", "Compétences numériques : outils de conception 3D",               ["Outils de conception 3D"]],
    ["1.7",   "Programmation impérative",                                       ["Programmation impérative"]],
    ["1.8",   "Méthodologie de la recherche documentaire",                      []],
    ["1.9",   "Découverte des compétences professionnelles chimie",             ["Découverte des compétences pro chimie"]],
    ["1.10",  "Découverte des compétences professionnelles mesures physiques",  ["Découverte des compétences pro mesures physiques"]],
    ["1.11",  "Découverte des compétences professionnelles Systèmes physiques", ["Découverte des compétences pro Syst physique"]],
    ["1.12",  "Projet (REH)",                                                   ["Projet (REH)"]],

    ["2.1",   "Calcul matriciel",                                               []],
    ["2.2",   "Calcul intégral",                                                []],
    ["2.3",   "Énergétique et circuits électriques",                            []],
    ["2.4",   "Mécanismes réactionnels chimiques",                              []],
    ["2.5.a", "Analyse",                                                        []],
    ["2.5.b", "Sciences pour l'ingénieur : Physique (ondes, physique nucléaire, électrostatique)", []],
    ["2.5.b", "Sciences pour l'ingénieur : Chimie (propriétés des éléments chimiques)",            []],
    ["2.6.a", "Activité d'ouverture : Sport",                                   []],
    ["2.6.b", "Activité d'ouverture : Transitions",                             []],
    ["2.7",   "Algorithmique",                                                  []],
    ["2.8",   "Anglais",                                                        []],
    ["2.9",   "PREPRO : Connaissance de soi",                                   []],
    ["2.10",  "Projet (REH) — semestre 2",                                      []]
  ].freeze

  Resultat = Struct.new(:codees, :creees, :orphelines, keyword_init: true) do
    def to_s
      "#{codees} UE existantes codées, #{creees} créées" +
        (orphelines.any? ? " · sans code : #{orphelines.join(', ')}" : "")
    end
  end

  def initialize(batch) = @batch = batch

  # Idempotent : rejouable sans dupliquer. Les UE déjà créées par l'import ADE
  # reçoivent leur code, les absentes de la maquette sont créées vides.
  def appliquer!(dry_run: false)
    codees = creees = 0
    vues = []

    ActiveRecord::Base.transaction do
      ENTREES.each_with_index do |(code, officiel, alias_ade), rang|
        ue = alias_ade.filter_map { |nom| Ue.find_by(batch: @batch, name: nom) }.first
        ue ||= Ue.find_by(batch: @batch, name: officiel)

        if ue
          ue.update!(code: code, position: rang)
          codees += 1
        else
          # Le nom officiel devient l'intitulé : aucune séance ADE ne s'y
          # rattache encore, il n'y a donc rien à préserver.
          ue = Ue.create!(batch: @batch, name: officiel, code: code, position: rang)
          creees += 1
        end
        vues << ue.id
      end

      orphelines = Ue.where(batch: @batch).where.not(id: vues).pluck(:name)
      raise ActiveRecord::Rollback if dry_run
      return Resultat.new(codees: codees, creees: creees, orphelines: orphelines)
    end

    Resultat.new(codees: codees, creees: creees,
                 orphelines: Ue.where(batch: @batch).where.not(id: vues).pluck(:name))
  end

  # Pour le menu déroulant : « 1.2 — Calcul fonctionnel », dans l'ordre.
  def self.pour_liste(batch)
    Ue.where(batch: batch).order(Arel.sql("position NULLS LAST"), :name).map do |ue|
      [ue.code.present? ? "#{ue.code} — #{ue.name}" : ue.name, ue.id]
    end
  end
end
