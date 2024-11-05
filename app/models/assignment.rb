class Assignment < ApplicationRecord
  belongs_to :user
  belongs_to :card
  validates :user, uniqueness: { scope: :card }

  def self.ransackable_attributes(auth_object = nil)
    ["card_id", "created_at", "id", "id_value", "updated_at", "user_id"]
  end


  def team
    user&.team
  end
end
