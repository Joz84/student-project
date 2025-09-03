class AddFieldsToCards < ActiveRecord::Migration[7.1]
  def change
    add_column :cards, :archived, :boolean
    add_column :cards, :teacher_validation, :integer
    add_column :cards, :time_estimate, :float
    add_column :cards, :time_unit, :string
  end
end
