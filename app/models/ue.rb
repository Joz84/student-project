# Une unité d'enseignement. Les groupes de TD et de TP lui sont rattachés,
# la répartition des étudiants changeant d'une UE à l'autre.
class Ue < ApplicationRecord
  belongs_to :batch
  has_many :groups, dependent: :destroy
  has_many :lessons, dependent: :nullify
  has_many :ue_assessments, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :batch_id }

  before_create :initialize_color

  # Une teinte par UE, attribuée à la suite au sein de la promotion : un
  # hachage du nom entrait en collision et deux matières se retrouvaient de la
  # même couleur, ce qui ôte tout intérêt au code couleur.
  TEINTES = %w[#2C6EB8 #89BF48 #E8A33D #9B6BD6 #43A9A0 #D96C6C
               #5B8DEF #C0A32E #7A6FD8 #3FA76B #D97B3F #B45C8E
               #2F8F8A #A8562E #6E8F2E #8E4FA8 #C43E6B #4E6FB5].freeze

  def teinte = color.presence || TEINTES.first

  private

  def initialize_color
    self.color ||= TEINTES[(batch ? Ue.where(batch_id: batch_id).count : 0) % TEINTES.size]
  end
end
