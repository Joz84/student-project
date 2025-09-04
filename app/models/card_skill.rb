class CardSkill < ApplicationRecord
  belongs_to :card
  belongs_to :skill
  validates :card, uniqueness: { scope: :skill }
end
