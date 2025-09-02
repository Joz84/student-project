class CreateBatches < ActiveRecord::Migration[7.1]
  def change
    create_table :batches do |t|
      t.string :title
      t.string :discord_link

      t.timestamps
    end
  end
end
