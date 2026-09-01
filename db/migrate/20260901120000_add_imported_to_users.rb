class AddImportedToUsers < ActiveRecord::Migration[7.1]
  def change
    # Compte créé depuis la liste administrative, et non par l'étudiant lui-même.
    add_column :users, :imported, :boolean, default: false, null: false
  end
end
