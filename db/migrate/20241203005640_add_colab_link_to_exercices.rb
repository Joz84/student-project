class AddColabLinkToExercices < ActiveRecord::Migration[7.1]
  def change
    add_column :exercices, :colab_link, :string
  end
end
