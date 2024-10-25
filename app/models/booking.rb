class Booking < ApplicationRecord
  belongs_to :team
  belongs_to :project
  validates :team, uniqueness: { scope: :project }
end
