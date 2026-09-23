class CreateImportRuns < ActiveRecord::Migration[7.1]
  def change
    # Trace des imports d'emploi du temps. Les journaux d'Heroku ne retiennent
    # qu'une heure : sans cette table, on ne peut pas savoir si la tâche
    # nocturne a tourné, ni ce qu'elle a changé.
    create_table :import_runs do |t|
      t.string :source, null: false
      t.datetime :started_at, null: false
      t.datetime :finished_at
      t.integer :created_count, default: 0
      t.integer :updated_count, default: 0
      t.integer :unchanged_count, default: 0
      t.integer :deleted_count, default: 0
      t.integer :kept_count, default: 0
      t.text :error
      t.timestamps
    end
    add_index :import_runs, :started_at
  end
end
