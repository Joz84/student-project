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
  has_many :attempts
  has_many :tickets
  validates :first_name, presence: true
  validates :first_name, presence: true
  validates :student_number, presence: true
  # validates :student_number, inclusion: { in: ["1", "2", "3"],
    # message: "Votre numéro étudiant n'est pas valide" }

  before_create :initialize_avatar_color
  after_create :create_ratings

  enum progress: [ :pending, :booked ]

  def to_s
    "#{first_name.capitalize} #{last_name.capitalize}"
  end

  def cw_nickname_exist?
    code = 100
    begin
      code = RestClient.get("https://www.codewars.com/api/v1/users/#{cw_nickname}").code
    rescue
      code = 404
    end
    if code != 200
      errors.add(:cw_nickname, "does not exist")
      false
    else
      true
    end
  end

  def cw_nickname_is_valid?
    !cw_nickname.blank? && 
    User.where
        .not(cw_nickname: nil)
        .find_by(cw_nickname: cw_nickname)
        .nil? &&
    cw_nickname_exist?
  end

  def update_attempts
    exercice_cw_tokens = Exercice.where
                                 .not(id: self.attempts.map(&:exercice_id))
                                 .map(&:cw_token)
                                 .uniq
    url = "https://www.codewars.com/api/v1/users/#{cw_nickname}/code-challenges/completed"
    begin
      if exercice_cw_tokens.count < Exercice.count
        all_completed_cw_token = JSON.parse(RestClient.get(url).body)["data"]
          .select{|kata| kata["completedLanguages"].include?("python")}
          .map{|kata| kata["id"]}.uniq
        completed_exercice_cw_tokens = (all_completed_cw_token & exercice_cw_tokens)
        completed_exercice_cw_tokens.each do |cw_token|
          Exercice.find_by(cw_token: cw_token).attempts.create(user: self)
        end
      end
    rescue
    end
  end

  private

  def create_ratings
    Project.all.map(&:id).each do |project_id|
      Rating.create(
        project_id: project_id, 
        user: self)
    end
  end

  def initialize_avatar_color
    r = rand(128..255)
    g = rand(128..255)
    b = rand(128..255)
    self.avatar_color = format("#%02X%02X%02X", r, g, b)
  end
end
