class Speciality < ApplicationRecord
  belongs_to :batch
  belongs_to :parent, class_name: "Speciality", optional: true
  has_many :children, class_name: "Speciality", foreign_key: :parent_id, dependent: :nullify
  has_many :users, dependent: :nullify
  has_many :project_specialities, dependent: :destroy
  has_many :projects, through: :project_specialities

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { scope: :batch_id }

  # tagged_only : accède aux projets taggés (les siens, ou ceux de son parent)
  # all_projects : accède à tous les projets de la promo (les indécis)
  enum project_access: { tagged_only: 0, all_projects: 1 }

  # La spécialité qui porte réellement les tags projets.
  # PEIP n'a pas de projet propre : il hérite de ceux de SI.
  def effective
    parent || self
  end

  def eligible_projects
    all_projects? ? batch.projects : effective.projects
  end

  def to_s
    name
  end

  def self.ransackable_attributes(auth_object = nil)
    ["batch_id", "created_at", "exclusive_groups", "id", "id_value", "name", "parent_id", "position", "project_access", "slug", "updated_at"]
  end
end
