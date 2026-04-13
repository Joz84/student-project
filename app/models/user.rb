class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :batch #, optional: true # remove after migration
  belongs_to :team, optional: true
  has_many :teams, dependent: :destroy  #as team leader
  has_many :ratings, dependent: :destroy 
  has_many :supervisions
  has_many :supervised_projects, through: :supervisions, source: :project
  has_many :supervised_batches, -> { distinct }, through: :supervised_projects, source: :batch
  has_many :supervised_teams, through: :supervised_projects, source: :teams
  has_many :assignments, dependent: :destroy 
  has_many :cards, through: :assignments
  has_many :attempts, dependent: :destroy 
  has_many :tickets, dependent: :destroy 
  has_many :messages, dependent: :destroy 
  has_many :presences, dependent: :destroy
  has_many :user_skill_statuses, dependent: :destroy
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :student_number, presence: true,
            format: { with: /\A\d{8}\z/, message: "doit contenir exactement 8 chiffres" }
  # validates :student_number, inclusion: { in: ["1", "2", "3"],
    # message: "Votre numéro étudiant n'est pas valide" }
  before_create :initialize_avatar_color
  after_create :create_ratings

  enum progress: [ :pending, :booked ]

  scope :kept, -> { where(drop: false) }


  def self.ransackable_associations(auth_object = nil)
    ["assignments", "attempts", "cards", "ratings", "supervisions", "team", "tickets"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["admin", "avatar_color", "created_at", "cw_nickname", "email", "encrypted_password", "first_name", "id", "id_value", "last_name", "progress", "remember_created_at", "reset_password_sent_at", "reset_password_token", "student_number", "teacher", "team_id", "updated_at"]
  end

  VALIDATION_NOTES = { 'one' => 2, 'two' => 3, 'three' => 4, 'accepted' => 5 }.freeze

  def skill_scores
    result = { validated: Hash.new(0.0), finalized: Hash.new(0.0), in_progress: Hash.new(0.0),
               note_weighted_sum: 0.0, note_total_weeks: 0.0 }
    cards.includes(:card_skills, :assignments).each do |card|
      weeks = case card.time_unit
              when "jour(s)"    then card.time_estimate / 5.0
              when "semaine(s)" then card.time_estimate
              when "mois"       then card.time_estimate * 4.0
              else 0.0
              end
      nb_users = card.assignments.size
      next if nb_users.zero?
      share = weeks / nb_users
      category = if card.accepted?
                   :validated
                 elsif card.archived?
                   :finalized
                 else
                   :in_progress
                 end
      card.card_skills.each do |card_skill|
        result[category][card_skill.skill_id] += share
      end
      note = VALIDATION_NOTES[card.teacher_validation]
      if note
        result[:note_weighted_sum] += share * note
        result[:note_total_weeks]  += share
      end
    end
    result
  end

  def all_teams
    Team.where(user_id: self.batch.users.pluck(:id))
  end

  def to_s
    "#{first_name.capitalize} #{last_name.capitalize}"
  end

  def slug
    "#{id} -- #{to_s}"
  end

  def cw_nickname_exist?(nickname=cw_nickname)
    code = 100
    begin
      code = RestClient.get("https://www.codewars.com/api/v1/users/#{nickname}").code
    rescue
      code = 404
    end
    if code != 200
      errors.add(:cw_nickname, "does not exist")
      errors.add(:exam_nickname, "does not exist")
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

  def exam_nickname_is_valid?
    !exam_nickname.blank? && 
    User.where
        .not(exam_nickname: nil)
        .find_by(exam_nickname: exam_nickname)
        .nil? &&
    cw_nickname_exist?(exam_nickname)
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

  def exam_exo_count 
    url = "https://www.codewars.com/api/v1/users/#{exam_nickname}/code-challenges/completed"
    begin
      all_completed_exam_token = JSON.parse(RestClient.get(url).body)["data"]
        .select{|kata| kata["completedLanguages"].include?("python")}
        .map{|kata| kata["id"]}.uniq
      all_completed_exam_token.count
    rescue
      0
    end
  end

  private

  def create_ratings
    Project.where(batch: self.batch).map(&:id).each do |project_id|
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
