class AddFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :student_number, :string
    add_column :users, :progress, :integer, default: 0
    add_column :users, :teacher, :boolean
  end
end
