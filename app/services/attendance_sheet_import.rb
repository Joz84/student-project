require "roo"

# Relecture d'une grille remplie hors ligne. On n'impose pas le vocabulaire
# exact : « P », « présent », « Absent justifié », « AJ » sont tous compris,
# parce qu'un fichier rempli à la main ne respecte jamais une nomenclature.
class AttendanceSheetImport
  MOTS = {
    "present" => %w[p pres present présent presente présente x oui 1],
    "absent"  => %w[a abs absent absente absentnonjustifie absentnonjustifié anj],
    "excused" => %w[aj absentjustifie absentjustifié justifie justifié excuse excusé e],
    "retard"  => %w[r retard enretard late]
  }.freeze

  Resultat = Struct.new(:maj, :inchangees, :effacees, :inconnus, :colonnes_ignorees,
                        :erreurs, keyword_init: true) do
    def to_s
      "#{maj} case#{'s' if maj > 1} mise#{'s' if maj > 1} à jour, #{inchangees} inchangée#{'s' if inchangees > 1}" +
        (effacees.positive? ? ", #{effacees} effacée#{'s' if effacees > 1}" : "") +
        (inconnus.any? ? " · #{inconnus.size} étudiant(s) non reconnu(s)" : "") +
        (colonnes_ignorees.any? ? " · colonnes ignorées : #{colonnes_ignorees.join(', ')}" : "")
    end
  end

  def initialize(sheet, fichier)
    @sheet = sheet
    @fichier = fichier
  end

  def run
    lignes = lire
    return Resultat.new(maj: 0, inchangees: 0, effacees: 0, inconnus: [],
                        colonnes_ignorees: [], erreurs: @erreur ? [@erreur] : ["Fichier vide."]) if lignes.blank?

    entetes = lignes.first.map { |c| c.to_s.strip }
    par_entete = @sheet.lessons.index_by { |l| AttendanceSheetExport.entete(l) }
    colonnes = {}
    ignorees = []
    entetes.each_with_index do |e, i|
      next if i < 3 || e.blank?
      if (l = par_entete[e]) then colonnes[i] = l else ignorees << e end
    end
    return Resultat.new(maj: 0, inchangees: 0, effacees: 0, inconnus: [], colonnes_ignorees: ignorees,
                        erreurs: ["aucune colonne de séance reconnue. Exportez la grille pour obtenir le bon format."]) if colonnes.empty?

    par_numero = @sheet.eleves.index_by { |e| e.student_number.to_s.strip }
    maj = inchangees = effacees = 0
    inconnus = []

    ActiveRecord::Base.transaction do
      lignes.drop(1).each do |ligne|
        numero = ligne[0].to_s.strip.sub(/\.0\z/, "")
        eleve = par_numero[numero]
        if eleve.nil?
          inconnus << numero if numero.present?
          next
        end
        colonnes.each do |i, lesson|
          statut = traduire(ligne[i])
          existant = Attendance.find_by(lesson_id: lesson.id, user_id: eleve.id)
          if statut.nil?
            next if ligne[i].to_s.strip.blank? && existant.nil?
            if ligne[i].to_s.strip.blank? && existant
              existant.destroy!
              effacees += 1
            else
              inchangees += 1
            end
            next
          end
          if existant&.status == statut
            inchangees += 1
          else
            (existant || Attendance.new(lesson_id: lesson.id, user_id: eleve.id))
              .update!(status: statut, declared_by: :teacher, declared_at: Time.current)
            maj += 1
          end
        end
      end
    end

    Resultat.new(maj: maj, inchangees: inchangees, effacees: effacees,
                 inconnus: inconnus.uniq, colonnes_ignorees: ignorees, erreurs: [])
  end

  private

  def lire
    extension = File.extname(@fichier.original_filename.to_s).downcase
    chemin = @fichier.tempfile.path
    tableur = case extension
              when ".xlsx" then Roo::Excelx.new(chemin)
              when ".xls"  then Roo::Excel.new(chemin)
              when ".csv"  then Roo::CSV.new(chemin, csv_options: { col_sep: separateur(chemin), encoding: "bom|utf-8" })
              else return (@erreur = "format #{extension} non géré, déposez un .xlsx ou un .csv") && nil
              end
    tableur.to_a
  rescue => e
    @erreur = "fichier illisible (#{e.class})"
    nil
  end

  def separateur(chemin)
    premiere = File.open(chemin, "r:bom|utf-8", &:readline) rescue ""
    premiere.count(";") >= premiere.count(",") ? ";" : ","
  end

  def traduire(valeur)
    v = I18n.transliterate(valeur.to_s).downcase.gsub(/[^a-z0-9]/, "")
    return nil if v.blank?
    MOTS.each { |statut, mots| return statut if mots.include?(v) }
    nil
  end
end
