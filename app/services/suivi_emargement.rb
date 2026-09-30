# Qui se sert de la feuille d'appel, et qui ne s'en sert pas.
#
# La question n'est pas « combien de pointages » mais « combien de séances ont
# donné lieu à un appel » : un enseignant qui pointe trente étudiants une fois
# n'est pas plus assidu que celui qui en pointe cinq à chaque cours.
#
# Une séance compte dès qu'elle a commencé — l'appel se fait pendant le cours —
# et les séances à venir sont hors du calcul.
class SuiviEmargement
  Ligne = Struct.new(:enseignant, :libelle, :seances, :appelees, :en_seance,
                     :validees, :dernier_appel, keyword_init: true) do
    # Une séance renseignée après coup depuis le relevé compte autant qu'un
    # appel pris en cours : le registre est tenu. Les distinguer dit seulement
    # quelle pratique s'installe.
    def apres_coup = appelees - en_seance

    def taux
      return nil if seances.zero?
      (100.0 * appelees / seances).round
    end

    def sans_compte? = enseignant.nil?

    # Trois états lisibles d'un coup d'œil plutôt qu'un pourcentage à
    # interpréter : qui n'a jamais essayé, qui a commencé, qui tient son registre.
    def etat
      return :sans_compte if sans_compte?
      return :jamais if appelees.zero?
      return :regulier if taux >= 70
      :partiel
    end

    ETATS = { sans_compte: "Sans compte", jamais: "Jamais", partiel: "Par moments",
              regulier: "Régulier" }.freeze

    def libelle_etat = ETATS[etat]
  end

  def initialize(batch, maintenant: Time.current)
    @batch = batch
    @maintenant = maintenant
  end

  def lignes
    @lignes ||= begin
      seances = Lesson.where(batch: @batch)
                      .where("starts_at <= ?", @maintenant)
                      .includes(:teacher).to_a
      # Une séance est tenue dès qu'elle porte un pointage, qu'il vienne de
      # l'appel en salle ou du relevé rempli plus tard.
      avec_appel = Attendance.where(lesson_id: seances.map(&:id))
                             .distinct.pluck(:lesson_id).to_set
      # Le code n'est posé que par l'ouverture de l'appel : sa présence
      # distingue les deux pratiques.
      ouvertes = seances.select { |l| l.attendance_code.present? }.map(&:id).to_set

      seances.group_by { |l| l.teacher_id || l.teacher_label.presence }
             .filter_map { |_, groupe|
               prof = groupe.first.teacher
               libelle = groupe.first.teacher_label.presence ||
                         (prof && "#{prof.last_name} #{prof.first_name}")
               next if libelle.nil? && prof.nil?

               appelees = groupe.select { |l| avec_appel.include?(l.id) }
               Ligne.new(enseignant: prof,
                         libelle: nettoyer(libelle),
                         seances: groupe.size,
                         appelees: appelees.size,
                         en_seance: appelees.count { |l| ouvertes.include?(l.id) },
                         validees: groupe.count(&:valide?),
                         dernier_appel: appelees.map(&:starts_at).max)
             }
             .sort_by { |l| [-l.seances, l.libelle.to_s.downcase] }
    end
  end

  def seances    = lignes.sum(&:seances)
  def appelees   = lignes.sum(&:appelees)
  def en_seance  = lignes.sum(&:en_seance)
  def apres_coup = lignes.sum(&:apres_coup)
  def validees   = lignes.sum(&:validees)
  def enseignants = lignes.size

  def taux
    return nil if seances.zero?
    (100.0 * appelees / seances).round
  end

  def par_etat = lignes.group_by(&:etat).transform_values(&:size)

  # L'évolution semaine par semaine : c'est elle qui dit si le dispositif
  # s'installe ou s'essouffle, ce qu'un taux global masque.
  def semaines(nombre = 8)
    fin = @maintenant.to_date.beginning_of_week
    debut = fin - (nombre - 1).weeks
    seances = Lesson.where(batch: @batch)
                    .where(starts_at: debut.beginning_of_day..@maintenant)
                    .pluck(:id, :starts_at)
    avec_appel = Attendance.where(lesson_id: seances.map(&:first)).distinct.pluck(:lesson_id).to_set

    debut.step(fin, 7).map do |lundi|
      dans_la_semaine = seances.select { |_, d| d.to_date.beginning_of_week == lundi }
      faites = dans_la_semaine.count { |id, _| avec_appel.include?(id) }
      { lundi: lundi, seances: dans_la_semaine.size, appelees: faites,
        taux: dans_la_semaine.empty? ? nil : (100.0 * faites / dans_la_semaine.size).round }
    end
  end

  # Les séances passées qu'aucun appel n'a touchées, les plus récentes d'abord.
  def seances_sans_appel(limite = 15)
    ids = Attendance.select(:lesson_id)
    Lesson.where(batch: @batch).where("starts_at <= ?", @maintenant)
          .where.not(id: ids).includes(:teacher, :ue)
          .order(starts_at: :desc).limit(limite)
  end

  def vide? = lignes.empty?

  private

  def nettoyer(libelle) = libelle.to_s.sub(/\s*\((M\.|Mme)\)\s*\z/, "").strip
end
