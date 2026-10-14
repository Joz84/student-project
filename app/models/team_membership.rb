# Trace du passage d'un étudiant dans une équipe.
#
# L'équipe du moment reste portée par `users.team_id` — tout l'applicatif en
# dépend. Cette table ne sert qu'à se souvenir : elle permet à une promotion
# d'afficher ses équipes une fois ses étudiants passés à la suivante, et à un
# étudiant de relire le tableau d'une année achevée.
class TeamMembership < ApplicationRecord
  belongs_to :user
  belongs_to :team

  validates :user_id, uniqueness: { scope: :team_id }

  scope :en_cours, -> { where(quittee_le: nil) }
  scope :passees, -> { where.not(quittee_le: nil) }

  def en_cours? = quittee_le.nil?

  # Enregistre le passage d'un étudiant d'une équipe à l'autre. Rejoindre une
  # équipe déjà fréquentée rouvre l'appartenance plutôt que d'en créer une
  # seconde : c'est la même histoire qui reprend.
  def self.suivre(user, ancienne_id, nouvelle_id, instant = Time.current)
    if ancienne_id
      where(user_id: user.id, team_id: ancienne_id).en_cours
        .update_all(quittee_le: instant, updated_at: instant)
    end
    return if nouvelle_id.nil?

    ligne = find_or_initialize_by(user_id: user.id, team_id: nouvelle_id)
    ligne.rejointe_le ||= instant
    ligne.quittee_le = nil
    ligne.save!
  end
end
