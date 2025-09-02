class AddDropToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :drop, :boolean, default: false
  end
end
