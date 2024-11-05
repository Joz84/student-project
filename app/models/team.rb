class Team < ApplicationRecord
  belongs_to :project, optional: true
  has_many :users, dependent: :nullify
  has_many :lists
  has_many :cards, through: :lists
  validates :name, presence: true
  validates :name, uniqueness: true

  def self.ransackable_associations(auth_object = nil)
    ["cards", "lists", "project", "users"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "drive_link", "id", "id_value", "name", "progress", "project_id", "trello_link", "updated_at"]
  end

  after_create :create_lists

  private

  def create_lists
    names = ["Tâches à faire", "Tâches en cours", "Tâches finalisées"]
    names.each_with_index do |name, index|
      List.create(
        team: self, 
        name: name,
        position: index
      )
    end
  end

end
