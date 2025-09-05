class CreateMeetings < ActiveRecord::Migration[7.1]
  def change
    create_table :meetings do |t|
      t.references :team, null: false, foreign_key: true
      t.references :referential, null: false, foreign_key: true
      t.string :place
      t.datetime :date
      t.integer :progress

      t.timestamps
    end
  end
end
