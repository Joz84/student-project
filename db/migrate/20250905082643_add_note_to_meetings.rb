class AddNoteToMeetings < ActiveRecord::Migration[7.1]
  def change
    add_column :meetings, :note, :text
  end
end
