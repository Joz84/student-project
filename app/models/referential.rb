class Referential < ApplicationRecord
  belongs_to :batch
  has_many :skill_blocks, dependent: :destroy
  has_many :skills, through: :skill_blocks
  validates :title, presence: true, uniqueness: true
end
