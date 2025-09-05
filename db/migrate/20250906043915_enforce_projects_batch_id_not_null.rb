class EnforceProjectsBatchIdNotNull < ActiveRecord::Migration[7.1]
  def up
    change_column_null :projects, :batch_id, false
  end

  def down
    change_column_null :projects, :batch_id, true
  end
end
