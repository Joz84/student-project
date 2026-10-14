# L'appartenance d'un étudiant à une équipe, conservée après coup.
#
# `users.team_id` ne dit que l'équipe du moment : changer de projet d'une
# année sur l'autre effaçait toute trace de la précédente, et la promotion
# qu'on venait de quitter se retrouvait vide de ses propres équipes.
class CreateTeamMemberships < ActiveRecord::Migration[7.1]
  def change
    create_table :team_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.datetime :rejointe_le, null: false
      t.datetime :quittee_le             # nulle tant qu'il y est encore
      t.timestamps
    end

    add_index :team_memberships, [:user_id, :team_id], unique: true
  end
end
