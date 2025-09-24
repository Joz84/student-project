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


end
