class ProjectSpeciality < ApplicationRecord
  belongs_to :project
  belongs_to :speciality
  validates :project, uniqueness: { scope: :speciality }
end
