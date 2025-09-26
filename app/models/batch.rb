class Batch < ApplicationRecord
  has_many :users
  has_many :referentials, dependent: :destroy
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

  def scores_json
    project_count = projects.count
    Rating.where( user: users.group_by{ |r| 
        ["#{r.user.slug}", "#{r.project.slug}"] 
      }.map{ |k, v| 
        [k, project_count - v.first.position + 1]}.to_h #.to_json
  end

end
