class AddLinksToTeams < ActiveRecord::Migration[7.1]
  def change
    add_column :teams, :drive_link, :string
    add_column :teams, :trello_link, :string
  end
end
