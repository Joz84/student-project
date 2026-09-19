namespace :timetable do
  desc "Rattache les étudiants aux groupes, d'après le classeur de la scolarité"
  task :memberships, [:fichier] => :environment do |_, args|
    batch = Batch.find_by(title: ENV.fetch("TIMETABLE_BATCH", "LSPI 2026-2029"))
    abort "Promotion introuvable" if batch.nil?
    chemin = args[:fichier] || ENV["MEMBERSHIPS_JSON"] ||
             abort("Indiquer le JSON produit par appartenances.py")
    lignes = JSON.parse(File.read(chemin))
    simulation = ENV["APPLY"] != "1"

    r = GroupMembershipsImporter.new(batch, lignes).run(dry_run: simulation)
    puts "#{simulation ? 'SIMULATION' : 'IMPORT'} — #{r}"
    r.sans_groupe.each { |ue, labs| warn "  groupe absent d'ADE — #{ue} : #{labs.join(', ')}" }
    warn "  #{r.sans_etudiant.size} numéros sans compte actif" if r.sans_etudiant.any?
  end

  desc "Importe les emplois du temps ADE de la promotion de L1"
  task import: :environment do
    batch = Batch.find_by(title: ENV.fetch("TIMETABLE_BATCH", "LSPI 2026-2029"))
    abort "Promotion introuvable" if batch.nil?
    codes = ENV.fetch("TIMETABLE_CODES", "dip-LIPMS1,dip-LIPMS1-IP").split(",")

    resultat = TimetableImporter.new(batch, codes).run
    puts "[#{Time.current.strftime('%d/%m %H:%M')}] #{batch.title} — #{resultat}"
    resultat.erreurs.each { |e| warn "  erreur : #{e}" }
  end
end
