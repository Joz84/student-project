class Assignment < ApplicationRecord
  belongs_to :user
  belongs_to :card
  validates :user, uniqueness: { scope: :card }
end
