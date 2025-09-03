class CreateSkillBlocks < ActiveRecord::Migration[7.1]
  def change
    create_table :skill_blocks do |t|
      t.string :title
      t.integer :position
      t.references :referential, null: false, foreign_key: true

      t.timestamps
    end
  end
end
