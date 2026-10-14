namespace :equipes do
  desc "Reprend l'historique des appartenances à partir des équipes actuelles"
  task historique: :environment do
    simulation = ENV["ECRIRE"] != "oui"
    crees = 0

    User.where.not(team_id: nil).find_each do |u|
      next if TeamMembership.exists?(user_id: u.id, team_id: u.team_id)
      crees += 1
      next if simulation
      TeamMembership.create!(user: u, team_id: u.team_id, rejointe_le: u.created_at)
    end

    puts "#{simulation ? '[simulation] ' : ''}#{crees} appartenance(s) en cours reprises"
    puts "Relancez avec ECRIRE=oui pour appliquer." if simulation
  end

  desc "Rattache un historique perdu : equipes:restaurer FICHIER=chemin.json"
  task restaurer: :environment do
    require "json"
    simulation = ENV["ECRIRE"] != "oui"
    carte = JSON.parse(File.read(ENV.fetch("FICHIER")))
    quand = ENV["QUAND"] ? Time.zone.parse(ENV["QUAND"]) : 1.year.ago

    # Un nom d'équipe n'est unique que dans une promotion : sans PROMO, deux
    # « Hydroponie » de deux années différentes se confondraient, et
    # l'historique irait se poser sur la mauvaise.
    portee = Team.all
    if ENV["PROMO"]
      promo = Batch.find(ENV["PROMO"])
      portee = portee.where(project_id: promo.projects.select(:id))
      puts "Promotion : #{promo.title}"
    end

    carte.each do |nom, ids|
      trouvees = portee.where(name: nom).to_a
      raise "#{trouvees.size} équipes nommées #{nom.inspect} : précisez PROMO=<id>" if trouvees.size != 1
      t = trouvees.first
      ids.each do |id|
        u = User.find(id)
        next if TeamMembership.exists?(user_id: u.id, team_id: t.id)
        puts "  #{u.last_name} → #{t.name}"
        next if simulation
        # Appartenance close : l'étudiant y était, il n'y est plus.
        TeamMembership.create!(user: u, team: t, rejointe_le: quand, quittee_le: Time.current)
      end
    end
    puts simulation ? "[simulation] Relancez avec ECRIRE=oui." : "Historique restauré."
  end
end
