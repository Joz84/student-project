class AddTdAndTpToUsers < ActiveRecord::Migration[7.1]
  def change
    # Groupes de travaux dirigés et pratiques, saisis depuis les listes
    # administratives : ils ne se déduisent pas des projets.
    add_column :users, :td, :string
    add_column :users, :tp, :string
    add_index :users, :td
    add_index :users, :tp
  end
end
