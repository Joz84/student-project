class Batch < ApplicationRecord
  has_many :users
  has_many :referentials, dependent: :destroy
  validates :title, presence: true, uniqueness: true

  def discord_server_url
    "https://discord.com/channels/#{discord_server_id}" if discord_server_id.present?
  end


end
