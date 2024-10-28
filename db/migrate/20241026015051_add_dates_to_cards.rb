class AddDatesToCards < ActiveRecord::Migration[7.1]
  def change
    add_column :cards, :begin_at, :datetime
    add_column :cards, :end_at, :datetime
  end
end
