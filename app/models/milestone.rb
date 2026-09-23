# Une grande étape de la feuille de route. Les tâches du tableau s'y
# rattachent, ce qui donne à la fois l'avancement du jalon et, sur chaque
# carte, l'étape à laquelle elle contribue.
class Milestone < ApplicationRecord
  belongs_to :team
  has_many :cards, dependent: :nullify

  acts_as_list scope: :team

  validates :name, presence: true
  validate :dates_coherentes

  before_create :initialize_color

  scope :ordonnes, -> { order(:position, :id) }

  TEINTES = %w[#2C6EB8 #89BF48 #E8A33D #9B6BD6 #43A9A0 #D96C6C].freeze

  def taches        = cards.where.not(status: :hidden)
  def taches_finies = taches.select(&:terminee?)

  def avancement
    total = taches.size
    return nil if total.zero?
    (100.0 * taches_finies.size / total).round
  end

  def en_retard?
    due_on.present? && due_on < Date.current && avancement.to_i < 100
  end

  def periode
    return nil if starts_on.blank? && due_on.blank?
    return "jusqu'au #{I18n.l(due_on, format: '%d/%m/%Y')}" if starts_on.blank?
    return "à partir du #{I18n.l(starts_on, format: '%d/%m/%Y')}" if due_on.blank?
    "du #{I18n.l(starts_on, format: '%d/%m')} au #{I18n.l(due_on, format: '%d/%m/%Y')}"
  end

  private

  def dates_coherentes
    return if starts_on.blank? || due_on.blank?
    errors.add(:due_on, "doit suivre la date de début") if due_on < starts_on
  end

  def initialize_color
    self.color ||= TEINTES[(team&.milestones&.count || 0) % TEINTES.size]
  end
end
