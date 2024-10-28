class CreateExercices < ActiveRecord::Migration[7.1]
  def change
    create_table :exercices do |t|
      t.string :name
      t.string :cw_token
      t.integer :position
      t.references :course, null: false, foreign_key: true
      t.boolean :visible
      t.integer :kata
      t.timestamps
    end
  end
end
