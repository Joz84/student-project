namespace :timetable do
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
