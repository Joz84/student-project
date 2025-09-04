class Skill < ApplicationRecord
  belongs_to :skill_block
  has_many :card_skills, dependent: :destroy
  
  def to_s
    "#{skill_block.position}.#{position} - #{title}"
  end
end
