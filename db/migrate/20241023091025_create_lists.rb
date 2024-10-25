class CreateLists < ActiveRecord::Migration[7.1]
  def change
    create_table :lists do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name

      t.timestamps
    end
  end
end
