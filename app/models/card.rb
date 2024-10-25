class Card < ApplicationRecord
  belongs_to :list
  has_many :assignments
  validates :name, presence: true
  validates :description, presence: true
end
