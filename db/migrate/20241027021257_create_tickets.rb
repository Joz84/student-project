class CreateTickets < ActiveRecord::Migration[7.1]
  def change
    create_table :tickets do |t|
      t.references :user, null: false, foreign_key: true
      t.string :content
      t.integer :progress, default: 0
      t.references :course, null: false, foreign_key: true

      t.timestamps
    end
  end
end
