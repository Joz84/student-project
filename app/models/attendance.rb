class Attendance < ApplicationRecord
  belongs_to :user
  belongs_to :lesson

  enum status: { absent: 0, present: 1, excused: 2 }
  enum declared_by: { student: 0, teacher: 1 }, _prefix: :by

  validates :user_id, uniqueness: { scope: :lesson_id }
end
