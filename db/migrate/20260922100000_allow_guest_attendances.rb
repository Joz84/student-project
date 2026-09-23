class AllowGuestAttendances < ActiveRecord::Migration[7.1]
  def change
    # Un étudiant peut se présenter sans figurer dans aucune liste : nouvel
    # inscrit, transfert, rattrapage. L'enseignant le saisit à la main, sans
    # contrainte de format, plutôt que de créer un compte bancal.
    change_column_null :attendances, :user_id, true
    add_column :attendances, :guest_first_name, :string
    add_column :attendances, :guest_last_name, :string
    add_column :attendances, :guest_student_number, :string
  end
end
