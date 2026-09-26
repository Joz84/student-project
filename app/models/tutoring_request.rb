# La demande de soutien d'un étudiant sur une UE, encadrée par les L3.
#
# Il n'y a pas de colonne d'état : la ligne existe ou non. Un étudiant qui se
# retire n'a pas à laisser une trace « ne veut plus », et les compteurs se
# lisent alors sans filtre.
class TutoringRequest < ApplicationRecord
  belongs_to :user
  belongs_to :ue

  validates :user_id, uniqueness: { scope: :ue_id }

  # Un compte désactivé ne compte plus dans la demande : il a quitté la promo.
  scope :vivantes, -> { joins(:user).merge(User.kept) }

  def self.demandee?(user, ue)
    exists?(user: user, ue: ue)
  end
end
