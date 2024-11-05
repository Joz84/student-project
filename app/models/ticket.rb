class Ticket < ApplicationRecord
  belongs_to :user
  belongs_to :course
  validates :content, presence: true

  def self.ransackable_attributes(auth_object = nil)
    ["content", "course_id", "created_at", "id", "id_value", "progress", "updated_at", "user_id"]
  end

  enum progress: [ :pending, :processing, :archived]
  before_validation do
    self.course = Course.where(ticket_activation: true).last
  end

  def str_progress
    case progress
    when "pending"
      "En attente"
    when "processing"
      "En cours"
    when "archived"
      "Archivé"
    end
  end

  def color_progress
    case progress
    when "pending"
      "#FF9D3D"
    when "processing"
      "#9BC963"
    end
  end
end
