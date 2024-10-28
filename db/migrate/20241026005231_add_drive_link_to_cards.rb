class AddDriveLinkToCards < ActiveRecord::Migration[7.1]
  def change
    add_column :cards, :drive_link, :string
  end
end
