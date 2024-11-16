class AddReadingToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :reading, :boolean
  end
end
