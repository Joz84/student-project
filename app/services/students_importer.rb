require "csv"

# Crée les comptes manquants d'une promo à partir de l'export administratif.
# Colonnes utilisées : « Code Apprenant » (numéro étudiant, 8 chiffres), « Nom »,
# « Prénom », « Email ». Les autres sont ignorées.
#
#   importer = StudentsImporter.new(Batch.find(67), File.read(csv))
#   puts importer.run(dry_run: true).report
#   puts importer.run(dry_run: false).report
#
# L'appariement évite les doublons en trois passes : numéro étudiant, puis
# e-mail, puis nom + prénom translittérés.
#
# Un redoublant a déjà un compte dans une promo précédente, et son e-mail est pris.
# On lui crée un second compte avec une adresse dérivée « prenom.nom2@etudiant.upf.pf »,
# incrémentée tant qu'elle est occupée. Quand son compte actuel est déjà une adresse
# universitaire, on repart de sa partie locale plutôt que de la recalculer.
class StudentsImporter
  CODE = "Code Apprenant".freeze
  NOM = "Nom".freeze
  PRENOM = "Prénom".freeze
  EMAIL = "Email".freeze
  DOMAINE = "@etudiant.upf.pf".freeze

  class Result
    attr_reader :created, :matched, :conflicts, :redoublants, :absent, :dry_run

    def initialize(created:, matched:, conflicts:, redoublants:, absent:, dry_run:)
      @created, @matched, @conflicts = created, matched, conflicts
      @redoublants, @absent, @dry_run = redoublants, absent, dry_run
    end

    def ok? = conflicts.empty?

    def report
      out = []
      out << (dry_run ? "SIMULATION — rien n'a été écrit" : "#{created.size} comptes créés")
      out << "  #{matched.size} déjà inscrits, appariés : " +
             matched.group_by { |m| m[:par] }.map { |k, v| "#{v.size} par #{k}" }.join(", ")
      out << "  #{created.size} à créer" if dry_run
      if conflicts.any?
        out << ""
        out << "  #{conflicts.size} ligne(s) non traitée(s) :"
        conflicts.each { |c| out << "     #{c}" }
      end
      if redoublants.any?
        out << ""
        out << "  #{redoublants.size} redoublant(s), adresse dérivée pour le nouveau compte :"
        redoublants.each do |r|
          out << "     #{r[:code]} #{r[:nom]} #{r[:prenom]}"
          out << "        ancien compte <#{r[:avant].email}> (#{r[:avant].batch&.title})"
          out << "        nouveau      <#{r[:apres]}>"
        end
      end
      if absent.any?
        out << ""
        out << "  #{absent.size} compte(s) de l'application absent(s) de la liste :"
        absent.each { |u| out << "     #{u.student_number} #{u} <#{u.email}>" }
      end
      if created.any?
        out << ""
        out << "  comptes #{dry_run ? 'qui seraient créés' : 'créés'} :"
        created.each { |u| out << "     #{u[:student_number]} #{u[:last_name]} #{u[:first_name]} <#{u[:email]}>" }
      end
      out.join("\n")
    end
  end

  def initialize(batch, csv_content)
    @batch = batch
    @rows = CSV.parse(csv_content.sub(/\A\xEF\xBB\xBF/, ""), headers: true, col_sep: ";")
  end

  def run(dry_run: true)
    created, matched, conflicts, redoublants = [], [], [], []
    vus = []

    @rows.each do |row|
      code = row[CODE].to_s.strip
      email = row[EMAIL].to_s.strip.downcase
      nom = row[NOM].to_s.strip
      prenom = row[PRENOM].to_s.strip

      if code.blank? || email.blank? || nom.blank? || prenom.blank?
        conflicts << "ligne incomplète : #{[code, nom, prenom, email].inspect}"
        next
      end

      existant, par = trouver(code, email, nom, prenom)
      if existant
        vus << existant.id
        matched << { user: existant, par: par }
        next
      end

      ancien = User.where("lower(email) = ?", email).first
      if ancien
        email = adresse_derivee(ancien, prenom, nom)
        redoublants << { code: code, nom: nom, prenom: prenom, avant: ancien, apres: email }
      end
      unless code.match?(/\A\d{8}\z/)
        conflicts << "#{code} #{nom} #{prenom} : numéro étudiant hors format (8 chiffres attendus)"
        next
      end

      created << { student_number: code, last_name: nom, first_name: prenom, email: email }
    end

    unless dry_run || conflicts.any?
      ActiveRecord::Base.transaction(requires_new: true) do
        created.each do |attrs|
          User.create!(attrs.merge(batch: @batch, imported: true,
                                   password: Devise.friendly_token(24)))
        end
      end
    end

    Result.new(created: created, matched: matched, conflicts: conflicts,
               redoublants: redoublants,
               absent: eleves.reject { |u| vus.include?(u.id) }, dry_run: dry_run)
  end

  private

  def eleves = @eleves ||= @batch.users.kept.where(teacher: nil).to_a

  def cle(*parts) = I18n.transliterate(parts.join(" ")).downcase.gsub(/[^a-z]/, "")

  # Espaces en tiret bas, apostrophes retirées, tirets conservés — convention
  # observée sur les adresses universitaires existantes.
  def partie(texte)
    I18n.transliterate(texte.to_s).downcase.strip
        .gsub(/['\u2019]/, "")
        .gsub(/\s+/, "_")
        .gsub(/[^a-z0-9_-]/, "")
  end

  def adresse_derivee(ancien, prenom, nom)
    base = if ancien.email.to_s.end_with?(DOMAINE)
             ancien.email.split("@").first
           else
             "#{partie(prenom)}.#{partie(nom)}"
           end
    n = 2
    loop do
      candidat = "#{base}#{n}#{DOMAINE}"
      return candidat unless User.where("lower(email) = ?", candidat).exists?
      n += 1
    end
  end

  def trouver(code, email, nom, prenom)
    if (u = eleves.find { |e| e.student_number.to_s.strip == code })
      return [u, "numéro étudiant"]
    end
    if (u = eleves.find { |e| e.email.to_s.downcase == email })
      return [u, "e-mail"]
    end
    if (u = eleves.find { |e| cle(e.last_name, e.first_name) == cle(nom, prenom) })
      return [u, "nom et prénom"]
    end
    [nil, nil]
  end
end
