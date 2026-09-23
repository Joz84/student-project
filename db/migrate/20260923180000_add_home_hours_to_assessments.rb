class AddHomeHoursToAssessments < ActiveRecord::Migration[7.1]
  def change
    # Heures de travail personnel déclarées par l'étudiant sur la matière.
    # L'attendu est d'en faire autant que d'heures reçues en présentiel.
    add_column :ue_assessments, :home_hours, :float, null: false, default: 0.0

    # Une ligne peut exister pour les seules heures de travail personnel,
    # sans que l'étudiant se soit encore situé sur l'échelle.
    change_column_null :ue_assessments, :level, true
    change_column_default :ue_assessments, :level, from: 0, to: nil
  end
end
