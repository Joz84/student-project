class CreateTimetableTables < ActiveRecord::Migration[7.1]
  def change
    # Une UE : « Calcul numérique et algébrique », « Programmation impérative ».
    create_table :ues do |t|
      t.references :batch, null: false, foreign_key: true
      t.string :name, null: false
      t.timestamps
    end
    add_index :ues, [:batch_id, :name], unique: true

    # Un groupe de TD ou de TP. La répartition variant d'une UE à l'autre,
    # le groupe appartient à l'UE et non à la promotion.
    create_table :groups do |t|
      t.references :ue, null: false, foreign_key: true
      t.string :label, null: false          # « TD-01 », « TP-03INFO »
      t.integer :kind, null: false, default: 0
      t.timestamps
    end
    add_index :groups, [:ue_id, :label], unique: true

    create_table :group_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :group, null: false, foreign_key: true
      t.timestamps
    end
    add_index :group_memberships, [:user_id, :group_id], unique: true

    # Une séance, telle qu'exportée par ADE.
    create_table :lessons do |t|
      t.references :batch, null: false, foreign_key: true
      t.references :ue, foreign_key: true
      t.references :teacher, foreign_key: { to_table: :users }
      t.string :ade_uid, null: false
      t.string :title, null: false
      t.string :room
      t.string :teacher_label                # nom tel qu'écrit par ADE
      t.integer :category, null: false, default: 0
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.string :attendance_code              # code à 4 chiffres affiché en salle
      t.datetime :locked_at                  # gel des pointages par l'enseignant
      t.datetime :validated_at
      t.timestamps
    end
    add_index :lessons, :ade_uid, unique: true
    add_index :lessons, :starts_at

    create_table :lesson_groups do |t|
      t.references :lesson, null: false, foreign_key: true
      t.references :group, null: false, foreign_key: true
      t.timestamps
    end
    add_index :lesson_groups, [:lesson_id, :group_id], unique: true

    create_table :attendances do |t|
      t.references :user, null: false, foreign_key: true
      t.references :lesson, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.integer :declared_by, null: false, default: 0
      t.datetime :declared_at
      t.timestamps
    end
    add_index :attendances, [:lesson_id, :user_id], unique: true
  end
end
