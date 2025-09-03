class CreateReferentials < ActiveRecord::Migration[7.1]
  def change
    create_table :referentials do |t|
      t.string :title
      t.boolean :active
      t.references :batch, null: false, foreign_key: true

      t.timestamps
    end
  end
end
