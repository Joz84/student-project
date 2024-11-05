class List < ApplicationRecord
  belongs_to :team
  has_many :cards
  validates :name, presence: true
  validates :name, uniqueness: { scope: :team }

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "id_value", "name", "position", "team_id", "updated_at"]
  end
end
