class CreateLists < ActiveRecord::Migration[7.1]
  def change
    create_table :lists do |t|
      t.references :team, null: false, foreign_key: true
      t.integer :position
      t.string :name

      t.timestamps
    end
  end
end
