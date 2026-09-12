class AddPartnerToProjects < ActiveRecord::Migration[7.1]
  def change
    add_column :projects, :partner, :string
  end
end
