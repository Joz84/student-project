class AddColorToProjects < ActiveRecord::Migration[7.1]
  def change
    add_column :projects, :color, :string
  end
end
