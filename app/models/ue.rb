# Une unité d'enseignement. Les groupes de TD et de TP lui sont rattachés,
# la répartition des étudiants changeant d'une UE à l'autre.
class Ue < ApplicationRecord
  belongs_to :batch
  has_many :groups, dependent: :destroy
  has_many :lessons, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: :batch_id }
end
