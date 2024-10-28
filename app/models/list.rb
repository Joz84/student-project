class List < ApplicationRecord
  belongs_to :team
  has_many :cards
  validates :name, presence: true
  validates :name, uniqueness: { scope: :team }
end
