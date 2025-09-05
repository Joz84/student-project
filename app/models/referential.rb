class Referential < ApplicationRecord
  belongs_to :batch
  has_many :skill_blocks, dependent: :destroy
  has_many :skills, through: :skill_blocks
  has_many :meetings
  validates :title, presence: true, uniqueness: true
end
