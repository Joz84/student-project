class List < ApplicationRecord
  belongs_to :project
  has_many :cards
  validates :name, presence: true
  validates :name, uniqueness: { scope: :project }
end
