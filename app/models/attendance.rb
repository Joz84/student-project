class Attendance < ApplicationRecord
  # Facultatif : une ligne peut désigner quelqu'un qui n'a pas de compte,
  # saisi à la main par l'enseignant.
  belongs_to :user, optional: true
  belongs_to :lesson

  # Sans préfixe, `present?` masquerait celui d'ActiveSupport : un pointage
  # absent répondrait « false » à la question « cet objet existe-t-il ? ».
  enum status: { absent: 0, present: 1, excused: 2 }, _prefix: :statut
  enum declared_by: { student: 0, teacher: 1 }, _prefix: :by

  validates :user_id, uniqueness: { scope: :lesson_id }, if: -> { user_id.present? }

  scope :invites, -> { where(user_id: nil) }

  def invite? = user_id.nil?

  def nom_complet
    return "#{user.first_name} #{user.last_name}" if user
    [guest_first_name, guest_last_name].map(&:presence).compact.join(" ").presence || "Sans nom"
  end

  def numero
    user&.student_number.presence || guest_student_number.presence
  end
end
