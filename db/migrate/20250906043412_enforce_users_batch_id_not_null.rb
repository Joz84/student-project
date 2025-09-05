class EnforceUsersBatchIdNotNull < ActiveRecord::Migration[7.1]
  def up
    change_column_null :users, :batch_id, false
  end

  def down
    change_column_null :users, :batch_id, true
  end
end
