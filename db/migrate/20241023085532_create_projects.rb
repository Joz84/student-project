class CreateProjects < ActiveRecord::Migration[7.1]
  def change
    create_table :projects do |t|
      t.string :name
      t.text :description
      t.integer :subject
      t.string :drive_link
      t.integer :max_booking
      t.string :author

      t.timestamps
    end
  end
end
