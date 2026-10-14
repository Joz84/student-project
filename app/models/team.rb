class Team < ApplicationRecord
  belongs_to :project, optional: true
  belongs_to :user #, optional: true #remove after migration #team leader
  has_many :users, dependent: :nullify
  has_many :team_memberships, dependent: :destroy
  has_many :anciens_membres, through: :team_memberships, source: :user
  has_many :lists
  has_many :milestones, dependent: :destroy
  has_many :cards, through: :lists
  # has_many :messages
  has_many :meetings, dependent: :destroy
  validates :name, presence: true
  # Deux promos peuvent porter le même nom d'équipe sans ambiguïté : « Hydroponie »
  # en L1 et en L2 désignent des projets distincts. L'unicité ne vaut donc que
  # dans une promotion, repérée par le projet de l'équipe.
  validate :name_unique_within_batch

  # Tous ceux qui ont composé l'équipe, présents et passés. C'est ce qu'une
  # promotion achevée doit continuer de montrer : ses équipes d'alors, avec
  # les étudiants qui y étaient, même partis en année supérieure.
  def membres
    (users.kept.to_a | anciens_membres.kept.to_a)
      .sort_by { |u| [u.last_name.to_s.downcase, u.first_name.to_s.downcase] }
  end

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
    div = users.kept.count.to_f * ((user.batch.projects.count - 1) * 2 + 1) / 100
    user.batch.projects.all.map { |project|
      rating = project.ratings.where(user: users.kept).map(&:score).sum / div
      [project, rating.round(2)]
    }.to_h
  end

  private

  def name_unique_within_batch
    return if name.blank?
    homonymes = Team.where(name: name).where.not(id: id)
    homonymes = if project
      homonymes.joins(:project).where(projects: { batch_id: project.batch_id })
    else
      homonymes.where(project_id: nil)
    end
    errors.add(:name, "est déjà utilisé dans cette promotion") if homonymes.exists?
  end

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
