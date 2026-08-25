class Batch < ApplicationRecord
  has_many :users
  has_many :referentials, dependent: :destroy
  has_many :specialities, -> { order(:position) }, dependent: :destroy
  has_many :projects
  has_many :teachers, through: :projects
  validates :title, presence: true, uniqueness: true

  def discord_server_url
    "https://discord.com/channels/#{discord_server_id}" if discord_server_id.present?
  end

  def current_referential
    referentials.find_by(active: true)
  end

  def project_slugs
    projects.map(&:slug)
  end

  def user_slugs
    users.map(&:slug)
  end

  def scores
    ratings_scores(users)
  end

  # Entrée complète du solveur (repartition_algorithme/repartition.py).
  # Contrairement à `scores`, ne retient que les étudiants encore présents.
  def solver_payload
    student_scope = users.kept.where(teacher: nil)
    {
      scores: ratings_scores(student_scope),
      projects: projects.map { |p| [p.slug, { max_booking: p.max_booking || 1 }] }.to_h,
      students: student_scope.map { |u| [u.slug, { speciality: u.speciality&.slug }] }.to_h,
      specialities: specialities.map { |s| [s.slug, { exclusive_groups: s.exclusive_groups }] }.to_h
    }
  end

  private

  def ratings_scores(user_scope)
    project_count = projects.count
    Rating.where(user: user_scope).group_by { |r|
        ["#{r.user.slug}", "#{r.project.slug}"]
      }.map { |k, v|
        [k, project_count - v.first.position + 1] }.to_h
  end

end
