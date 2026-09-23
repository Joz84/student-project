class KeyLessonsOnTheirSlot < ActiveRecord::Migration[7.1]
  def change
    # ADE a changé de schéma d'UID entre deux exports : aucun identifiant du
    # 18 septembre ne se retrouve dans celui du 22. L'UID ne peut donc pas
    # servir de clé. Une séance est identifiée par son créneau, son intitulé
    # et sa salle, qui eux sont stables — 334 séances sur 363 se retrouvent
    # d'un export à l'autre.
    remove_index :lessons, :ade_uid
    add_index :lessons, :ade_uid
    add_index :lessons, [:batch_id, :starts_at]
    change_column_null :lessons, :ade_uid, true
  end
end
