# La liste complémentaire d'une matière s'ouvre à deux choses de plus.
#
# Un compte peut y figurer : un étudiant inscrit dans une autre promotion, ou
# rattaché à aucun groupe, doit pouvoir être ajouté durablement sans qu'on lui
# invente une appartenance de TD.
#
# Et l'ajout porte une portée : l'enseignant qui saisit quelqu'un choisit si
# c'est pour cette séance seulement ou pour toute la matière.
class ExtendUeGuests < ActiveRecord::Migration[7.1]
  def change
    add_reference :ue_guests, :user, foreign_key: true, null: true
    add_column :ue_guests, :permanent, :boolean, default: true, null: false
    add_index :ue_guests, [:ue_id, :permanent]
  end
end
