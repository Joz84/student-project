class Project < ApplicationRecord
  has_many :teams
  has_many :ratings
  has_many :supervisons
  validates :name, presence: true
  validates :description, presence: true

  enum subject: [ :physique, :chimie ]
end
