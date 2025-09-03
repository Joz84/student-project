class CreateSkills < ActiveRecord::Migration[7.1]
  def change
    create_table :skills do |t|
      t.string :title
      t.integer :position
      t.references :skill_block, null: false, foreign_key: true
      t.integer :evaluated

      t.timestamps
    end
  end
end
