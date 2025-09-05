class Meeting < ApplicationRecord
  belongs_to :team
  belongs_to :referential
  has_many :presences, dependent: :destroy
  accepts_nested_attributes_for :presences

  validates :date, presence: true
  validates :place, presence: true 
  enum progress: [ :past ] 
  after_create :create_presences

  def create_presences
    team.users.kept.each do |user|
      Presence.create(user: user, meeting: self)
    end
  end
end
