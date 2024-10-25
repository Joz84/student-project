class CreateSupervisions < ActiveRecord::Migration[7.1]
  def change
    create_table :supervisions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true

      t.timestamps
    end
  end
end
