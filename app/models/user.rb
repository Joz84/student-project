class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :team, optional: true
  has_many :ratings
  has_many :supervisons
  has_many :assignments
  has_many :cards, through: :assignments
  validates :first_name, presence: true
  validates :first_name, presence: true
  validates :student_number, presence: true
  validates :student_number, inclusion: { in: ["1", "2", "3"],
    message: "Votre numéro étudiant n'est pas valide" }

  after_create :create_ratings

  enum progress: [ :pending, :booked ]

  private

  def create_ratings
    Project.all.map(&:id).each do |project_id|
      Rating.create(
        project_id: project_id, 
        user: self, 
        position: 0)
    end
  end
end
