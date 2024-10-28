class AddCwNicknameToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :cw_nickname, :string
  end
end
