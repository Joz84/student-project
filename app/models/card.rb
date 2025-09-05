class Card < ApplicationRecord
  belongs_to :list
  acts_as_list scope: :list
  has_many :assignments, dependent: :destroy
  has_many :card_skills, dependent: :destroy  
  has_many :users, through: :assignments
  validates :name, presence: true
  validates :description, presence: true
  validates :time_estimate, presence: true
  validates :time_unit, presence: true

  enum status: [ :active, :archived, :hidden ]
  enum teacher_validation: [ :pending, :refused, :one, :two, :three, :accepted ]
  def self.ransackable_attributes(auth_object = nil)
    ["begin_at", "created_at", "description", "drive_link", "end_at", "id", "id_value", "list_id", "name", "position", "updated_at"]
  end

  attr_reader :old_list, :new_list, :old_index, :new_index

  def team
    list&.team
  end

  def str_begin_at
    begin_at ? format_date(begin_at) : nil 
  end

  def str_end_at
    end_at ? format_date(end_at) : nil
  end

  private

  def format_date(date)
    date.strftime("%d/%m/%y") 
  end

end
