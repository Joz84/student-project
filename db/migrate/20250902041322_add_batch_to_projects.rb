class AddBatchToProjects < ActiveRecord::Migration[7.1]
  def change
    add_reference :projects, :batch, null: true, foreign_key: true
  end
end
