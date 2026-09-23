require "csv"

# Export de la grille. Le fichier produit est aussi le format attendu à
# l'import : les en-têtes de colonne servent de clé, ce qui garantit
# l'aller-retour sans documentation séparée.
class AttendanceSheetExport
  def initialize(sheet) = @sheet = sheet

  def to_csv
    # Le BOM évite qu'Excel massacre les accents à l'ouverture.
    "﻿" + CSV.generate(col_sep: ";") do |csv|
      csv << ["Numéro", "Nom", "Prénom"] + @sheet.lessons.map { |l| self.class.entete(l) }
      @sheet.eleves.each do |e|
        csv << [e.student_number, e.last_name, e.first_name] +
               @sheet.lessons.map { |l| Attendance::LIBELLES[@sheet.statut(l, e)] }
      end
    end
  end

  # La clé d'une colonne. Le groupe est indispensable : deux séances d'une
  # même UE peuvent commencer à la même minute pour deux groupes différents.
  def self.entete(lesson)
    [lesson.starts_at.strftime("%d/%m/%Y %H:%M"),
     lesson.groups.order(:label).map(&:label).join("+").presence].compact.join(" ")
  end
end
