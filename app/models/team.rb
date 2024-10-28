class Team < ApplicationRecord
  belongs_to :project, optional: true
  has_many :users, dependent: :nullify
  has_many :lists
  has_many :cards, through: :lists
  validates :name, presence: true
  validates :name, uniqueness: true

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
