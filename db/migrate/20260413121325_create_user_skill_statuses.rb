class CreateUserSkillStatuses < ActiveRecord::Migration[7.1]
  def change
    create_table :user_skill_statuses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :skill, null: false, foreign_key: true
      t.integer :status, default: 0, null: false

      t.timestamps
    end
    add_index :user_skill_statuses, [:user_id, :skill_id], unique: true
  end
end
