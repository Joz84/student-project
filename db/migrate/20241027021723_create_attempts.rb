class CreateAttempts < ActiveRecord::Migration[7.1]
  def change
    create_table :attempts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :exercice, null: false, foreign_key: true
      t.boolean :succeeded

      t.timestamps
    end
  end
end
