# Un ajout « sur toute la matière » visait jusqu'ici toutes les séances de
# l'UE, tous groupes confondus : un étudiant inscrit depuis le TP-01 se
# retrouvait attendu au TP-04, au TP-05 et partout ailleurs.
#
# Le groupe précise la portée. Nul signifie toujours « toute la matière »,
# ce qui garde le sens des lignes déjà créées.
class AddGroupToUeGuests < ActiveRecord::Migration[7.1]
  def change
    add_reference :ue_guests, :group, foreign_key: true, null: true
  end
end
