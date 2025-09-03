class AddDiscordFieldsToBatches < ActiveRecord::Migration[7.1]
  def change
    add_column :batches, :discord_server_id, :string
    add_column :batches, :discord_invite_url, :string
  end
end
