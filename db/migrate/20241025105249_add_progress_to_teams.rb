class AddProgressToTeams < ActiveRecord::Migration[7.1]
  def change
    add_column :teams, :progress, :integer, default: 0
  end
end
