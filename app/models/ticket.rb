class Ticket < ApplicationRecord
  belongs_to :user
  belongs_to :course
  validates :content, presence: true

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
