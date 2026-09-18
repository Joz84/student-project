require "net/http"

# Lecture d'un flux iCalendar produit par ADE, l'outil de planification de
# l'université. Le flux est public et chaque séance porte un UID stable, ce
# qui permet de rejouer l'import sans créer de doublon.
class AdeCalendar
  HOTE = "https://icsviewer.apps.upf.pf/ics-srv/ics_diplome.php"

  # « TD-01 », « TP-03INFO », « TD-01-OPTION2 », « CM »
  JETON = /\b(CM|TD|TP)(?:-(\d{1,2}))?(INFO)?(?:-(OPTION\d+))?\b/

  Seance = Struct.new(:uid, :titre, :ue, :salle, :enseignant, :debut, :fin,
                      :categorie, :groupes, keyword_init: true)

  def self.telecharger(code)
    uri = URI("#{HOTE}?id=#{code}")
    reponse = Net::HTTP.get_response(uri)
    raise "ADE a répondu #{reponse.code} pour #{code}" unless reponse.is_a?(Net::HTTPSuccess)
    reponse.body.force_encoding("UTF-8")
  end

  def self.seances(ics)
    evenements(ics).map { |e| interpreter(e) }.compact
  end

  # Les lignes ICS de plus de 75 caractères sont repliées : une ligne qui
  # commence par une espace prolonge la précédente.
  def self.evenements(ics)
    lignes = []
    ics.gsub("\r\n", "\n").split("\n").each do |l|
      if l.start_with?(" ", "\t") && lignes.any?
        lignes[-1] += l[1..]
      else
        lignes << l
      end
    end

    evs = []
    courant = nil
    lignes.each do |l|
      case l
      when "BEGIN:VEVENT" then courant = {}
      when "END:VEVENT"   then evs << courant if courant
      else
        next unless courant && l.include?(":")
        cle, valeur = l.split(":", 2)
        courant[cle.split(";").first] = valeur
      end
    end
    evs
  end

  def self.interpreter(e)
    return nil if e["DTSTART"].blank? || e["UID"].blank?

    resume = deplier(e["SUMMARY"])
    description = deplier(e["DESCRIPTION"])
    lignes_desc = description.split("\\n").map(&:strip).reject(&:empty?)

    jetons = (resume.scan(JETON) + description.scan(JETON)).map { |m| normaliser(m) }.uniq
    groupes = jetons.reject { |j| j[:label] =~ /\A(CM|TD|TP)\z/ }

    Seance.new(
      uid: e["UID"],
      titre: resume,
      ue: nom_ue(resume, lignes_desc),
      salle: deplier(e["LOCATION"]).presence,
      enseignant: lignes_desc.find { |l| l =~ /\((M\.|Mme)\)\z/ },
      debut: horodatage(e["DTSTART"]),
      fin: horodatage(e["DTEND"] || e["DTSTART"]),
      categorie: categorie(resume, description, jetons),
      groupes: groupes
    )
  end

  def self.normaliser(m)
    type, numero, info, option = m
    label = type.dup
    label += "-#{numero.rjust(2, '0')}" if numero
    label += "INFO" if info
    label += "-#{option}" if option
    genre = if option then :option
            elsif info then :tp_info
            elsif type == "TP" then :tp
            elsif type == "TD" then :td
            else :cm
            end
    { label: label, kind: genre }
  end

  # L'intitulé de l'UE est ce qui suit le préfixe de groupe. Quand le résumé
  # n'en porte pas (« TD - SPI : Méthodes chimiques »), la description contient
  # la forme complète.
  def self.nom_ue(resume, lignes_desc)
    candidats = [resume] + lignes_desc
    candidats.each do |c|
      if (m = c.match(/\A(?:#{JETON}(?:\s*\/\s*#{JETON})*)\s+-\s+(.+)\z/))
        return m.captures.last.strip
      end
    end
    nil
  end

  def self.categorie(resume, description, jetons)
    return :exam if description =~ /Examen|2nde chance|Tiers temps/i || resume =~ /\ACC\d/
    genres = jetons.map { |j| j[:kind] }
    return :cm if genres.include?(:cm)
    return :tp_info if genres.include?(:tp_info)
    return :tp if genres.include?(:tp)
    return :td if genres.any? { |g| g == :td || g == :option }
    :autre
  end

  def self.deplier(v) = v.to_s.gsub("\\,", ",").gsub("\;", ";").strip

  # ADE exporte en UTC ; Tahiti est à UTC-10.
  def self.horodatage(v)
    return nil if v.blank?
    Time.find_zone("UTC").parse(v.delete("Z"))&.in_time_zone(Time.zone)
  end
end
