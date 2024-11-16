class AddReadingDateToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :reading_date, :datetime
  end
end
