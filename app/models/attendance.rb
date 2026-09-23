class Attendance < ApplicationRecord
  belongs_to :user
  belongs_to :lesson

  # Sans préfixe, `present?` masquerait celui d'ActiveSupport : un pointage
  # absent répondrait « false » à la question « cet objet existe-t-il ? ».
  enum status: { absent: 0, present: 1, excused: 2 }, _prefix: :statut
  enum declared_by: { student: 0, teacher: 1 }, _prefix: :by

  validates :user_id, uniqueness: { scope: :lesson_id }
end
