class CreatePresences < ActiveRecord::Migration[7.1]
  def change
    create_table :presences do |t|
      t.references :user, null: false, foreign_key: true
      t.references :meeting, null: false, foreign_key: true
      t.integer :progress

      t.timestamps
    end
  end
end
