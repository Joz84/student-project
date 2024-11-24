class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :team, optional: true
  has_many :ratings
  has_many :supervisions
  has_many :supervised_projects, through: :supervisions, source: :project
  has_many :supervised_teams, through: :supervised_projects, source: :teams
  has_many :assignments
  has_many :cards, through: :assignments
  has_many :attempts
  has_many :tickets
  has_many :messages
  validates :first_name, presence: true
  validates :first_name, presence: true
  validates :student_number, presence: true
  # validates :student_number, inclusion: { in: ["1", "2", "3"],
    # message: "Votre numéro étudiant n'est pas valide" }

  def self.ransackable_associations(auth_object = nil)
    ["assignments", "attempts", "cards", "ratings", "supervisions", "team", "tickets"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["admin", "avatar_color", "created_at", "cw_nickname", "email", "encrypted_password", "first_name", "id", "id_value", "last_name", "progress", "remember_created_at", "reset_password_sent_at", "reset_password_token", "student_number", "teacher", "team_id", "updated_at"]
  end


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
      if exercice_cw_tokens.count > 0
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

  def old_team_messages(selected_team = team)
    Message.where('created_at <= ?', reading_date)
           .where(team: selected_team)
  end

  def new_team_messages(selected_team = team)
    Message.where('created_at > ?', reading_date)
           .where(team: selected_team)
  end

  def new_team_messages_count
    new_team_messages.count
  end

  def all_new_team_messages_count
    Message.where('created_at > ?', reading_date)
           .where(team: supervised_teams)
           .count
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
