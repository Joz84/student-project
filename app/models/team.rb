class Team < ApplicationRecord
  belongs_to :project, optional: true
  belongs_to :user #, optional: true #remove after migration #team leader
  has_many :users, dependent: :nullify
  has_many :lists
  has_many :cards, through: :lists
  # has_many :messages
  has_many :meetings, dependent: :destroy
  validates :name, presence: true
  validates :name, uniqueness: true

  def archived_cards
    cards.where(status: :archived)
  end

  def next_meeting
    meetings.where("date >= ?", DateTime.now).order(date: :asc).first
  end

  scope :kept, -> { joins(:users).merge(User.kept).distinct }

  def self.ransackable_associations(auth_object = nil)
    ["cards", "lists", "project", "users"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "drive_link", "id", "id_value", "name", "progress", "project_id", "trello_link", "updated_at"]
  end

  after_create :create_lists

  def project_ratings
    div = users.kept.count.to_f * ((Project.count - 1) * 2 + 1) / 100
    user.batch.projects.all.map { |project|
      rating = project.ratings.where(user: users.kept).map(&:score).sum / div
      [project, rating.round(2)]
    }.to_h
  end

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
