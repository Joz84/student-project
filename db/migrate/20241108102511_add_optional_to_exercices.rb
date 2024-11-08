class AddOptionalToExercices < ActiveRecord::Migration[7.1]
  def change
    add_column :exercices, :optional, :boolean
  end
end
