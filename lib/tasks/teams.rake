namespace :teams do
  desc "Crée les équipes d'une promo depuis la sortie du solveur. " \
       "BATCH=<id|titre> FILE=<chemin.json> [DRY_RUN=1]"
  task import: :environment do
    batch = Batch.find_by(id: ENV["BATCH"]) || Batch.find_by(title: ENV["BATCH"])
    abort "BATCH manquant ou introuvable (id ou titre exact)" if batch.nil?
    abort "FILE manquant" if ENV["FILE"].blank?
    abort "fichier introuvable : #{ENV['FILE']}" unless File.exist?(ENV["FILE"])

    result = TeamsImporter.new(batch, File.read(ENV["FILE"]))
                          .run(dry_run: ENV["DRY_RUN"].present?)
    puts result.report
    abort "" unless result.ok?
  end
end
