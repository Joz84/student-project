class SkillBlock < ApplicationRecord
  belongs_to :referential
  has_many :skills, dependent: :destroy
end
