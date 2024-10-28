class AddPositionToCards < ActiveRecord::Migration[7.1]
  def change
    add_column :cards, :position, :integer
  end
end
