class AddBatchToUsers < ActiveRecord::Migration[7.1]
  def change
    add_reference :users, :batch, null: true, foreign_key: true
  end
end
