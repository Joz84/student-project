# L'assiduité des étudiants d'une promotion.
#
# Deux notions à ne pas confondre. « Attendu » se lit dans les groupes : une
# séance de TP ne vise qu'un cinquième de la promotion. « Renseigné » est ce
# que l'enseignant a effectivement saisi — et comme tous ne tiennent pas leur
# feuille, un étudiant peut n'avoir aucun pointage sans avoir manqué un cours.
#
# Le taux de présence se calcule donc sur les séances renseignées, jamais sur
# les séances attendues : sinon il mesurerait l'assiduité des enseignants.
class Assiduite
  Ligne = Struct.new(:user, :attendues, :renseignees, :presents, :absents,
                     :excuses, :retards, keyword_init: true) do
    def manquantes = renseignees - presents - retards

    # Sur ce qui est renseigné : c'est la seule base honnête.
    def taux
      return nil if renseignees.zero?
      (100.0 * (presents + retards) / renseignees).round
    end

    # La part du registre réellement tenue pour cet étudiant. Un taux de
    # présence calculé sur trois séances sur quarante ne vaut pas grand-chose,
    # et cette colonne le dit.
    def couverture
      return nil if attendues.zero?
      (100.0 * renseignees / attendues).round
    end

    def etat
      return :inconnu if renseignees < 3
      return :alerte if taux < 60
      return :irregulier if taux < 85
      :assidu
    end

    ETATS = { inconnu: "Trop peu de données", alerte: "En décrochage",
              irregulier: "Irrégulier", assidu: "Assidu" }.freeze

    def libelle_etat = ETATS[etat]
  end

  def initialize(batch, maintenant: Time.current)
    @batch = batch
    @maintenant = maintenant
  end

  def lignes
    @lignes ||= begin
      pointages = Attendance.where(lesson_id: seances.map(&:id)).where.not(user_id: nil)
                            .pluck(:user_id, :status)
                            .group_by(&:first)

      etudiants.map do |u|
        etats = (pointages[u.id] || []).map(&:last).tally
        Ligne.new(
          user: u,
          attendues: attendues_par_etudiant[u.id].to_i,
          renseignees: etats.values.sum,
          presents: etats["present"].to_i,
          absents: etats["absent"].to_i,
          excuses: etats["excused"].to_i,
          retards: etats["retard"].to_i
        )
      end.sort_by { |l| [l.taux || 999, l.user.last_name.to_s.downcase] }
    end
  end

  def etudiants
    @etudiants ||= User.kept.where(teacher: nil, batch: @batch)
                       .order(:last_name, :first_name).to_a
  end

  # Les séances déjà commencées : une séance à venir n'est attendue de personne.
  def seances
    @seances ||= Lesson.where(batch: @batch).where("starts_at <= ?", @maintenant)
                       .includes(:groups).to_a
  end

  def attendues_par_etudiant
    @attendues_par_etudiant ||= begin
      compte = Hash.new(0)
      avec, sans = seances.partition { |l| l.group_ids.any? }

      par_groupe = GroupMembership.where(group_id: avec.flat_map(&:group_ids).uniq)
                                  .pluck(:group_id, :user_id)
                                  .each_with_object(Hash.new { |h, k| h[k] = [] }) { |(g, u), h| h[g] << u }
      avec.each do |l|
        l.group_ids.flat_map { |g| par_groupe[g] }.uniq.each { |uid| compte[uid] += 1 }
      end

      # Une séance sans groupe — un CM — vise toute la promotion.
      ids_promo = etudiants.map(&:id)
      sans.each { ids_promo.each { |uid| compte[uid] += 1 } }
      compte
    end
  end

  def renseignees = lignes.sum(&:renseignees)
  def presents    = lignes.sum(&:presents)
  def absents     = lignes.sum(&:absents)
  def excuses     = lignes.sum(&:excuses)
  def retards     = lignes.sum(&:retards)

  def taux
    return nil if renseignees.zero?
    (100.0 * (presents + retards) / renseignees).round
  end

  def par_etat = lignes.group_by(&:etat).transform_values(&:size)

  def vide? = lignes.empty? || renseignees.zero?

  # Le détail d'un seul étudiant, matière par matière.
  def self.par_matiere(user, maintenant: Time.current)
    groupes = user.group_ids
    seances = Lesson.where("starts_at <= ?", maintenant)
                    .where(ue_id: Ue.where(id: Group.where(id: groupes).select(:ue_id)))
                    .includes(:ue, :groups).to_a
                    .select { |l| l.groups.empty? || (l.group_ids & groupes).any? }
    pointages = Attendance.where(lesson_id: seances.map(&:id), user_id: user.id)
                          .index_by(&:lesson_id)

    seances.group_by(&:ue).map { |ue, lot|
      etats = lot.filter_map { |l| pointages[l.id]&.status }.tally
      { ue: ue, attendues: lot.size, renseignees: etats.values.sum,
        presents: etats["present"].to_i, absents: etats["absent"].to_i,
        excuses: etats["excused"].to_i, retards: etats["retard"].to_i,
        manquees: lot.filter_map { |l| l if %w[absent excused].include?(pointages[l.id]&.status) } }
    }.sort_by { |m| -m[:attendues] }
  end
end
