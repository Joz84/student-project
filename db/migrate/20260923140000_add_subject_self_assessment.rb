class AddSubjectSelfAssessment < ActiveRecord::Migration[7.1]
  def change
    add_column :ues, :color, :string

    # Auto-évaluation de l'étudiant sur une UE. La table accueillera plus tard
    # les connaissances travaillées : d'où une cible polymorphe, pour ne pas
    # avoir à la refondre.
    create_table :ue_assessments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :ue, null: false, foreign_key: true
      t.integer :level, null: false, default: 0
      t.timestamps
    end
    add_index :ue_assessments, [:user_id, :ue_id], unique: true
  end
end
