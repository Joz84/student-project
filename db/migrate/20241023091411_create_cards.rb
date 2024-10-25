class CreateCards < ActiveRecord::Migration[7.1]
  def change
    create_table :cards do |t|
      t.references :list, null: false, foreign_key: true
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
