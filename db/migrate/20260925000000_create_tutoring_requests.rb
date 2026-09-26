# Une demande de soutien : l'étudiant signale vouloir être tutoré sur une UE.
# La présence de la ligne vaut la demande, comme pour les pointages où
# l'absence de ligne est un état à part entière. Retirer sa demande la supprime.
class CreateTutoringRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :tutoring_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.references :ue,   null: false, foreign_key: true
      t.timestamps
    end

    add_index :tutoring_requests, [:user_id, :ue_id], unique: true
  end
end
