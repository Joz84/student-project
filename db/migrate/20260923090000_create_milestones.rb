class CreateMilestones < ActiveRecord::Migration[7.1]
  def change
    # Un jalon : la grande étape d'une feuille de route, à laquelle les tâches
    # du tableau se rattachent.
    create_table :milestones do |t|
      t.references :team, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.date :starts_on
      t.date :due_on
      t.integer :position
      t.string :color
      t.timestamps
    end
    add_index :milestones, [:team_id, :position]

    add_reference :cards, :milestone, foreign_key: true
  end
end
