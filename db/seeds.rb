# Attempt.destroy_all
# Exercice.destroy_all
# Ticket.destroy_all
# Course.destroy_all
# Card.destroy_all
# List.destroy_all
# Team.destroy_all
# Rating.destroy_all
# Project.destroy_all
# User.destroy_all

# User.create!(admin: true, email: "dev@mihivai.com", password: 'azerty', first_name: "Dev", last_name: "Upf", student_number: 1, teacher: true, cw_nickname: "")  
# User.create!(email: "student@gmail.com", password: 'azerty', first_name: "Bob", last_name: "Upf", student_number: 2)

batch = Batch.create!(
  title: "LSPI 2025-2028",
  discord_server_id: "1412629379552641037",
  discord_invite_url: "https://discord.gg/79d2K6CZ"
)

Project.create!(
  batch: batch,
  name: "Totem", 
  description: " Réalisation d'un boitier de collecte de données sur un support (totem) pour évaluer la
performance de bâtiments portant sur les conditions de confort, la qualité de l'air (IAQ), la santé
cognitive des occupants et les consommations électriques. Ce totem sera basé sur l'utilisation de
technologies (capteurs, contrôleurs) low cost et la réalisation de pièces par imprimante 3D.", 
  subject: :physique, 
  max_booking: 4, 
  author: 'Franck Lucas', 
  active: true
)

Project.create!(
  batch: batch,
  name: "Robot Tiki", 
  description: "L'objectif principal de ce projet est de concevoir et construire un robot innovant capable de se mouvoir sur deux roues tout en maintenant son équilibre, grâce à un système de stabilisation utilisant un gyroscope connecté à un processeur Arduino. Ce robot, original par sa capacité à s'équilibrer et à se déplacer en autonomie, constitue une plateforme idéale pour expérimenter et appliquer des compétences pluridisciplinaires des sciences de l'ingénieur.", 
  subject: :physique, 
  max_booking: 5, 
  author: 'Franco Ferrucci', 
  active: true
)

Project.create!(
  batch: batch,
  name: "Raquette connectée", 
  description: "Projet mené avec la Fédération polynésienne de ping-pong : concevoir une raquette connectée mesurant et transmettant en temps réel les gestes. IMU (gyro/accéléro), microcontrôleur (Arduino/ESP32), BLE/Wi-Fi et batterie intégrés au manche. Visualisation et analyse sur app, estimation vitesse/spin, détection d’impact, avec comparaison à une raquette du commerce. Objectif : précision, autonomie et ergonomie.",
  subject: :physique, 
  max_booking: 1, 
  author: 'Jonathan Serafini', 
  active: true
)

Project.create!(
  batch: batch,
  name: "Ressource en eau dans les atolls", 
  description: "Ressource en eau dans les atolls",
  subject: :chimie, 
  max_booking: 1, 
  author: 'Jeremy Yune', 
  active: true
)

Project.create!(
  batch: batch,
  name: "Hydroponie", 
  description: "Réalisation d'installations de culture hydroponique (voir figure ci-dessous) intégrant une
gestion et une collecte de données permettant l'automatisation d'apport en nutriment ainsi qu'en
eau. L'alimentation se fera en prenant en compte l'environnement extérieur, les nutriments présents
dans un réservoir d'eau afin d'en améliorer la production végétale et organique des aliments ainsi
que des consommations d'énergie. Ce système sera basé sur l'utilisation de technologies (capteurs,
contrôleurs) low cost et la réalisation de pièces par imprimante 3D.", 
  subject: :physique, 
  max_booking: 5, 
  author: 'Anthony Utahia', 
  active: true
)

Project.create!(
  batch: batch,
  name: "Chimie Accepe", 
  description: "Comprendre les mécanismes de production des substances naturelles (métabolites secondaires) dans les plantes.
Comparer la composition chimique de différentes plantes récoltées sur plusieurs sites présentant des conditions environnementales contrastées.
Étudier l'influence de paramètres environnementaux (température, humidité, composition du sol, exposition à la lumière, pollution, etc.) sur la concentration des métabolites secondaires dans les plantes.
Maîtriser des techniques analytiques comme la chromatographie et la spectroscopie pour l'analyse chimique.
Réaliser des analyses statistiques pour comparer les résultats obtenus selon les sites et les conditions étudiées.", 
  subject: :chimie, 
  max_booking: 1, 
  author: 'Raimana Ho', 
  active: true
)

Project.create!(
  batch: batch,
  name: "Chimie Extramet", 
  description: "Apprendre et maîtriser diverses techniques d'extraction de substances naturelles en utilisant des solvants variés (eau, éthanol, acétone).
Calculer les rendements d'extraction et les comparer pour chaque solvant et chaque échantillon étudié.
Utiliser la loi de Beer-Lambert pour quantifier les substances extraites par spectrophotométrie.
Comparer la concentration d'une substance naturelle extraite à partir d'une source terrestre ou marine avec un produit commercial similaire.
Maîtriser la démarche expérimentale complète depuis la préparation des extraits jusqu'à leur caractérisation quantitative.", 
  subject: :chimie, 
  max_booking: 1, 
  author: 'Raimana Ho', 
  active: true
)


# kept_users = [
#   {:first_name=>"Hawaiki", :last_name=>"Tchen"},
#   {:first_name=>"Killian", :last_name=>"TEMAURI"},
#   {:first_name=>"Havaiki", :last_name=>"BOSSERT"},
#   {:first_name=>"Heremoana", :last_name=>"Dagues"},
#   {:first_name=>"Eric", :last_name=>"LAO KY SOI"},
#   {:first_name=>"Aotea", :last_name=>"TEFAATAU--GONIN"},
#   {:first_name=>"Oatea", :last_name=>"Tarrats"},
#   {:first_name=>"Keona", :last_name=>"Duval"},
#   {:first_name=>"Ariimihinoa", :last_name=>"Lai Ah Che"},
#   {:first_name=>"Rahan", :last_name=>"TCHAN"},
#   {:first_name=>"Teani", :last_name=>"CUZACQ--CARRASSET"},
#   {:first_name=>"Kalei", :last_name=>"TETUAMANUHIRI "},
#   {:first_name=>"Bryan", :last_name=>"LIVINE"},
#   {:first_name=>"Marunui", :last_name=>"TERIIEROOITERAI"},
#   {:first_name=>"Manutahi", :last_name=>"Maono"}
# ]

# kept_users.each do |user|
#   User.find_by(user).update!(drop: false)
# end  

#Referential.destroy_all

ref = Referential.create!(
  title: "LSPI-1 2025-2026", 
  active: true,
  batch: batch
)

skill_block_titles = [
  "Identification d'un questionnement au sein d'un champ disciplinaire",
  "Analyse d'un questionnement en mobilisant des concepts disciplinaires",
  "Mise en oeuvre de méthodes et d'outils du champ disciplinaire",
  "Usages digitaux et numériques",
  "Exploitation de données à des fins d'analyse",
  "Expression et communication écrites et orales",
  "Positionnement vis-à-vis d'un champ professionnel",
  "Action en responsabilité au sein d'une organisation professionnelle",
  "Approches durables des techniques"
]

skill_block_titles.each_with_index do |title, index|
  SkillBlock.create!(
    title: title, 
    position: index + 1,
    referential: ref
  )
end

skills = [
  [ 1, 3, "Identifier les principales familles de matériaux et leurs propriétés."],
  [ 1, 3, "Mobiliser des concepts en mathématiques, en physique, en chimie, en thermodynamique, afin d'aborder des problèmes spécifiques aux différents domaines industriels."],
  [ 2, 3, "Identifier le rôle et le champ d'application des sciences pour l'ingénieur dans tous les secteurs : milieux naturels, milieux industriels, transports, environnements urbains, etc.."],
  [ 3, 3, "Valider un modèle par comparaison de ses prévisions aux résultats expérimentaux et apprécier ses limites de validité."],
  [ 3, 3, "Mobiliser les outils mathématiques nécessaires à la modélisation."],
  [ 3, 3, "Estimer les ordres de grandeur et manipuler correctement les unités."],
  [ 3, 3, "Intégrer une vision correcte de l'espace et de ses représentations."],
  [ 3, 3, "Isoler un système."],
  [ 3, 3, "Mettre en oeuvre des techniques d'algorithmique et de programmation, notamment pour développer des applications simples d'acquisition et de traitements de données."],
  [ 4, 3, "Utiliser les outils numériques de référence et les règles de sécurité informatique pour acquérir, traiter, produire et diffuser de l'information ainsi que pour collaborer en interne et en externe."],
  [ 5, 3, "Identifier, sélectionner et analyser avec esprit critique diverses ressources dans son domaine de spécialité pour documenter un sujet et synthétiser ces données en vue de leur exploitation."],
  [ 5, 3, "Analyser et synthétiser des données en vue de leur exploitation."],
  [ 5, 3, "Développer une argumentation avec esprit critique."],
  [ 6, 3, "Se servir aisément des différents registres d'expression écrite et orale de la langue française."],
  [ 6, 0, "Communiquer par oral et par écrit, de façon claire et non-ambiguë, dans au moins une langue étrangère."],
  [ 7, 3, "Identifier et situer les champs professionnels potentiellement en relation avec les acquis de la mention ainsi que les parcours possibles pour y accéder."],
  [ 7, 3, "Caractériser et valoriser son identité, ses compétences et son projet professionnel en fonction d'un contexte."],
  [ 7, 3, "Identifier le processus de production, de diffusion et de valorisation des savoirs."],
  [ 8, 3, "Situer son rôle et sa mission au sein d'une organisation pour s'adapter et prendre des initiatives."],
  [ 8, 3, "Respecter les principes d'éthique, de déontologie et de responsabilité environnementale."],
  [ 8, 3, "Travailler en équipe et en réseau ainsi qu'en autonomie et responsabilité au service d'un projet."],
  [ 8, 3, "Analyser ses actions en situation professionnelle, s'autoévaluer pour améliorer sa pratique."],
  [ 8, 3, "S'appuyer sur la pensée critique et faire preuve de réflexivité."],
  [ 9, 3, "Etre en mesure d'évaluer et identifier des solutions pour réduire les impacts environnementaux des techniques."],
  [ 9, 3, "Articuler les savoir-faire de différents champs disciplinaires dans un contexte de décision ou d'action."],
  [ 9, 3, "Maitriser les outils d'évaluation multicritères et transformer les outils existants."],
  [ 9, 3, "Adopter une approche systémique."],
  [ 9, 3, "Comprendre les scenarios existants et être capable d'engager une démarche prospective."],
  [ 9, 3, "Tenir compte des risques et incertitudes dans les scénarios."]
]
																																	
skills.each_with_index do |skill, index|
  Skill.create!(
    title: skill[2], 
    position: index + 1,
    skill_block: SkillBlock.find_by(position: skill[0]), 
    evaluated: skill[1]
  )
end