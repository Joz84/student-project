class Project < ApplicationRecord
  belongs_to :batch
  has_many :teams
  has_many :ratings
  has_many :supervisions
  has_many :teachers, through: :supervisions, source: :user
  validates :name, presence: true
  validates :description, presence: true

  enum subject: [ :physique, :chimie ]

  before_create :initialize_avatar_color

  def initialize_color
    r = rand(128..255)
    g = rand(128..255)
    b = rand(128..255)
    self.color = format("#%02X%02X%02X", r, g, b)
  end
end
