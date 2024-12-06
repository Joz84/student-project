class AddMeetingToTeams < ActiveRecord::Migration[7.1]
  def change
    add_column :teams, :meeting_date, :datetime
    add_column :teams, :meeting_place, :string
  end
end
