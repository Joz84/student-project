namespace :timetable do
  desc "Affiche les dernières exécutions de l'import"
  task journal: :environment do
    runs = ImportRun.recentes.limit(10)
    abort "Aucun import enregistré." if runs.empty?
    puts "#{'quand'.ljust(18)} #{'durée'.rjust(6)}  résultat"
    runs.each do |r|
      puts "#{I18n.l(r.started_at, format: '%d/%m %H:%M').ljust(18)} #{"#{r.duree}s".rjust(6)}  #{r.resume}"
    end
    puts "\nà jour : #{ImportRun.a_jour? ? 'oui' : 'NON — aucune exécution réussie depuis plus de 36 h'}"
  end

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

    trace = ImportRun.create!(source: codes.join(","), started_at: Time.current)
    begin
      resultat = TimetableImporter.new(batch, codes).run
      trace.update!(finished_at: Time.current,
                    created_count: resultat.creees, updated_count: resultat.majs,
                    unchanged_count: resultat.inchangees,
                    deleted_count: resultat.supprimees.to_i, kept_count: resultat.conservees.to_i,
                    error: resultat.erreurs.first(5).join(" ; ").presence)
      puts "[#{Time.current.strftime('%d/%m %H:%M')}] #{batch.title} — #{resultat}"
      resultat.erreurs.each { |e| warn "  erreur : #{e}" }
    rescue => e
      # L'échec doit laisser une trace, sans quoi une tâche qui plante chaque
      # nuit est indiscernable d'une tâche qui n'existe pas.
      trace.update!(finished_at: Time.current, error: "#{e.class} : #{e.message}")
      raise
    end
  end

  desc "Applique la maquette officielle de L1 : codes sur les UE existantes, création des manquantes"
  task :maquette, [:promo] => :environment do |_t, args|
    titre = args[:promo] || "LSPI 2026-2029"
    batch = Batch.find_by!(title: titre)
    simulation = ENV["ECRIRE"] != "oui"
    resultat = MaquetteL1.new(batch).appliquer!(dry_run: simulation)
    puts "#{simulation ? '[simulation] ' : ''}#{titre} : #{resultat}"
    puts "Relancez avec ECRIRE=oui pour appliquer." if simulation
  end

  desc "Rattache les séances orphelines aux comptes, d'après les alias ADE"
  task :alias, [:promo] => :environment do |_t, args|
    titre = args[:promo] || "LSPI 2026-2029"
    batch = Batch.find_by!(title: titre)
    simulation = ENV["ECRIRE"] != "oui"

    alias_par_cle = User.where(teacher: true).where.not(ade_label: [nil, ""])
                        .each_with_object({}) { |u, h| h[u.ade_label] = u }

    orphelines = Lesson.where(batch: batch, teacher_id: nil).where.not(teacher_label: [nil, ""])
    par_libelle = orphelines.group_by(&:teacher_label)

    if par_libelle.empty?
      puts "#{titre} : aucune séance orpheline."
      next
    end

    par_libelle.sort_by { |_, s| -s.size }.each do |libelle, seances|
      prof = alias_par_cle[libelle]
      if prof
        puts format("  %-32s → ##%-4d %-38s %3d séances", libelle, prof.id, prof.email, seances.size)
        Lesson.where(id: seances.map(&:id)).update_all(teacher_id: prof.id) unless simulation
      else
        puts format("  %-32s   aucun alias déclaré%13s %3d séances", libelle, "", seances.size)
      end
    end

    puts simulation ? "[simulation] Relancez avec ECRIRE=oui pour rattacher." : "Rattachement effectué."
  end
end
