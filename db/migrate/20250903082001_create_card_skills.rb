class CreateCardSkills < ActiveRecord::Migration[7.1]
  def change
    create_table :card_skills do |t|
      t.references :card, null: false, foreign_key: true
      t.references :skill, null: false, foreign_key: true
      t.integer :level

      t.timestamps
    end
  end
end
