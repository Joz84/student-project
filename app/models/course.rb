class Course < ApplicationRecord
  has_many :exercices
  has_many :tickets
  validates :name, presence: true
  # validates :github_link, presence: true
  validates :slides_link, presence: true
  validates :position, presence: true
end
