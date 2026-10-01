# Où en sont les étudiants dans ce qu'ils déclarent eux-mêmes : leur niveau
# par matière, leurs heures de travail personnel, leurs demandes de soutien.
#
# C'est une mesure d'usage autant que de niveau. Un étudiant qui n'a rien
# rempli n'est pas en difficulté : il n'a rien rempli, et c'est une autre
# conversation.
class AvancementEtudiants
  Ligne = Struct.new(:user, :evaluations, :niveaux, :heures_maison,
                     :demandes, :derniere_saisie, keyword_init: true) do
    def evaluees = niveaux.size

    # Moyenne sur l'échelle à quatre degrés, quand il s'est situé quelque part.
    def niveau_moyen
      return nil if niveaux.empty?
      (niveaux.sum { |n| UeAssessment::NOTES[n].to_f } / niveaux.size).round(2)
    end

    def fragiles = niveaux.count { |n| %w[notion initiation].include?(n) }

    def etat
      return :muet if evaluees.zero?
      return :alerte if niveau_moyen && niveau_moyen < 2
      return :en_cours if niveau_moyen && niveau_moyen < 3
      :a_laise
    end

    ETATS = { muet: "N'a rien rempli", alerte: "Se dit en difficulté",
              en_cours: "En apprentissage", a_laise: "À l'aise" }.freeze

    def libelle_etat = ETATS[etat]
  end

  def initialize(batch)
    @batch = batch
  end

  def lignes
    @lignes ||= begin
      ues = Ue.where(batch: @batch).pluck(:id)
      evals = UeAssessment.where(ue_id: ues, user_id: etudiants.map(&:id)).to_a
                          .group_by(&:user_id)
      demandes = TutoringRequest.where(ue_id: ues, user_id: etudiants.map(&:id))
                                .group(:user_id).count

      etudiants.map do |u|
        lot = evals[u.id] || []
        Ligne.new(user: u, evaluations: lot,
                  niveaux: lot.filter_map(&:level),
                  heures_maison: lot.sum { |e| e.home_hours.to_f }.round(1),
                  demandes: demandes[u.id].to_i,
                  derniere_saisie: lot.map(&:updated_at).max)
      end.sort_by { |l| [-l.evaluees, l.user.last_name.to_s.downcase] }
    end
  end

  def etudiants
    @etudiants ||= User.kept.where(teacher: nil, batch: @batch)
                       .order(:last_name, :first_name).to_a
  end

  def actifs      = lignes.count { |l| l.evaluees.positive? }
  def muets       = lignes.count { |l| l.evaluees.zero? }
  def evaluations = lignes.sum(&:evaluees)
  def heures      = lignes.sum(&:heures_maison).round(1)
  def demandeurs  = lignes.count { |l| l.demandes.positive? }

  def participation
    return 0 if lignes.empty?
    (100.0 * actifs / lignes.size).round
  end

  def par_niveau
    lignes.flat_map(&:niveaux).tally
  end

  def par_etat = lignes.group_by(&:etat).transform_values(&:size)

  def vide? = lignes.empty?
end
