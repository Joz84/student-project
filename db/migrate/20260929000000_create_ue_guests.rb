# Les étudiants qu'un enseignant ajoute lui-même à la liste d'une matière :
# un nouvel inscrit, un auditeur, quelqu'un que la scolarité n'a pas encore
# rattaché. Ils n'ont pas de compte, seulement les bribes d'identité dont
# l'enseignant dispose.
#
# Jusqu'ici une telle ligne n'existait qu'au travers d'un pointage, ce qui
# interdisait d'inscrire quelqu'un sans le déclarer présent quelque part.
class CreateUeGuests < ActiveRecord::Migration[7.1]
  def change
    create_table :ue_guests do |t|
      t.references :ue, null: false, foreign_key: true
      t.string :first_name
      t.string :last_name
      t.string :student_number
      t.timestamps
    end
  end
end
