class AddToDescriptionToExercices < ActiveRecord::Migration[7.1]
  def change
    add_column :exercices, :description, :text
  end
end
