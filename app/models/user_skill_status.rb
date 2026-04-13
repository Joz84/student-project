class UserSkillStatus < ApplicationRecord
  belongs_to :user
  belongs_to :skill

  enum status: { discovered: 0, acquiring: 1, acquired: 2 }
end
