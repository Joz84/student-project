class LessonGroup < ApplicationRecord
  belongs_to :lesson
  belongs_to :group
end
