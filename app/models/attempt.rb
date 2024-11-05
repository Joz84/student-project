class Attempt < ApplicationRecord
  belongs_to :user
  belongs_to :exercice


  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "exercice_id", "id", "id_value", "succeeded", "updated_at", "user_id"]
  end
end
