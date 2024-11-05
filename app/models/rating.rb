class Rating < ApplicationRecord
  belongs_to :user
  belongs_to :project
  acts_as_list scope: :user

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "id_value", "position", "project_id", "updated_at", "user_id"]
  end
end
