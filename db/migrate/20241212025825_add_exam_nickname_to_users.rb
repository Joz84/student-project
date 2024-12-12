class AddExamNicknameToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :exam_nickname, :string
  end
end
