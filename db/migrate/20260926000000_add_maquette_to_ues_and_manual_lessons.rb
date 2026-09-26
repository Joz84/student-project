# Deux ajouts liés : le code de la maquette sur les UE, pour qu'un enseignant
# choisisse son cours dans la liste officielle et non dans les intitulés
# d'ADE ; et un drapeau sur les séances créées à la main, que l'import
# nocturne ne doit pas effacer en réconciliant avec le flux.
class AddMaquetteToUesAndManualLessons < ActiveRecord::Migration[7.1]
  def change
    add_column :ues, :code, :string
    add_column :ues, :position, :integer
    add_index  :ues, [:batch_id, :position]

    add_column :lessons, :manuelle, :boolean, default: false, null: false
    add_index  :lessons, :manuelle
  end
end
