class CreateCourses < ActiveRecord::Migration[7.1]
  def change
    create_table :courses do |t|
      t.string :name
      t.string :github_link
      t.string :slides_link
      t.integer :position

      t.timestamps
    end
  end
end
