class CreateSpecialities < ActiveRecord::Migration[7.1]
  def change
    create_table :specialities do |t|
      t.references :batch, null: false, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false
      t.integer :position
      t.references :parent, foreign_key: { to_table: :specialities }
      t.integer :project_access, default: 0, null: false
      t.boolean :exclusive_groups, default: false, null: false
      t.timestamps
    end
    add_index :specialities, [:batch_id, :slug], unique: true

    create_table :project_specialities do |t|
      t.references :project, null: false, foreign_key: true
      t.references :speciality, null: false, foreign_key: true
      t.timestamps
    end
    add_index :project_specialities, [:project_id, :speciality_id], unique: true

    add_reference :users, :speciality, foreign_key: true
  end
end
