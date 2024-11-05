class Supervision < ApplicationRecord
  belongs_to :user
  belongs_to :project

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "id_value", "project_id", "updated_at", "user_id"]
  end
end
