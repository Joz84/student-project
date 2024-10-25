class Team < ApplicationRecord
  has_many :bookings
  has_many :users, dependent: :nullify
  validates :name, presence: true
  validates :name, uniqueness: true

  enum progress: [ :pending, :booked ]

  def project
    bookings.find()
  end
end
