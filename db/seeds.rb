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

# batch = Batch.create!(
#   title: "LSPI 2025-2028",
#   discord_server_id: "1412629379552641037",
#   discord_invite_url: "https://discord.gg/79d2K6CZ"
# )

# Project.create!(
#   batch: batch,
#   name: "Totem", 
#   description: " Réalisation d'un boitier de collecte de données sur un support (totem) pour évaluer la
# performance de bâtiments portant sur les conditions de confort, la qualité de l'air (IAQ), la santé
# cognitive des occupants et les consommations électriques. Ce totem sera basé sur l'utilisation de
# technologies (capteurs, contrôleurs) low cost et la réalisation de pièces par imprimante 3D.", 
#   subject: :physique, 
#   max_booking: 4, 
#   author: 'Franck Lucas', 
#   active: true
# )

# Project.create!(
#   batch: ,
#   name: "E-Foil", 
#   description: "E-Foil", 
#   subject: :physique, 
#   max_booking: 1, 
#   author: 'Franck Lucas', 
#   active: true
# )

# Project.create!(
#   batch: batch,
#   name: "Raquette connectée", 
#   description: "Projet mené avec la Fédération polynésienne de ping-pong : concevoir une raquette connectée mesurant et transmettant en temps réel les gestes. IMU (gyro/accéléro), microcontrôleur (Arduino/ESP32), BLE/Wi-Fi et batterie intégrés au manche. Visualisation et analyse sur app, estimation vitesse/spin, détection d’impact, avec comparaison à une raquette du commerce. Objectif : précision, autonomie et ergonomie.",
#   subject: :physique, 
#   max_booking: 1, 
#   author: 'Jonathan Serafini', 
#   active: true
# )

# Project.create!(
#   batch: batch,
#   name: "Ressource en eau dans les atolls", 
#   description: "Ressource en eau dans les atolls",
#   subject: :chimie, 
#   max_booking: 1, 
#   author: 'Jeremy Yune', 
#   active: true
# )

# Project.create!(
#   batch: batch,
#   name: "Hydroponie", 
#   description: "Réalisation d'installations de culture hydroponique (voir figure ci-dessous) intégrant une
# gestion et une collecte de données permettant l'automatisation d'apport en nutriment ainsi qu'en
# eau. L'alimentation se fera en prenant en compte l'environnement extérieur, les nutriments présents
# dans un réservoir d'eau afin d'en améliorer la production végétale et organique des aliments ainsi
# que des consommations d'énergie. Ce système sera basé sur l'utilisation de technologies (capteurs,
# contrôleurs) low cost et la réalisation de pièces par imprimante 3D.", 
#   subject: :physique, 
#   max_booking: 5, 
#   author: 'Anthony Utahia', 
#   active: true
# )

# Project.create!(
#   batch: batch,
#   name: "Chimie Accepe", 
#   description: "Comprendre les mécanismes de production des substances naturelles (métabolites secondaires) dans les plantes.
# Comparer la composition chimique de différentes plantes récoltées sur plusieurs sites présentant des conditions environnementales contrastées.
# Étudier l'influence de paramètres environnementaux (température, humidité, composition du sol, exposition à la lumière, pollution, etc.) sur la concentration des métabolites secondaires dans les plantes.
# Maîtriser des techniques analytiques comme la chromatographie et la spectroscopie pour l'analyse chimique.
# Réaliser des analyses statistiques pour comparer les résultats obtenus selon les sites et les conditions étudiées.", 
#   subject: :chimie, 
#   max_booking: 1, 
#   author: 'Raimana Ho', 
#   active: true
# )

# Project.create!(
#   batch: batch,
#   name: "Chimie Extramet", 
#   description: "Apprendre et maîtriser diverses techniques d'extraction de substances naturelles en utilisant des solvants variés (eau, éthanol, acétone).
# Calculer les rendements d'extraction et les comparer pour chaque solvant et chaque échantillon étudié.
# Utiliser la loi de Beer-Lambert pour quantifier les substances extraites par spectrophotométrie.
# Comparer la concentration d'une substance naturelle extraite à partir d'une source terrestre ou marine avec un produit commercial similaire.
# Maîtriser la démarche expérimentale complète depuis la préparation des extraits jusqu'à leur caractérisation quantitative.", 
#   subject: :chimie, 
#   max_booking: 1, 
#   author: 'Raimana Ho', 
#   active: true
# )


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

# ref = Referential.create!(
#   title: "LSPI-1 2025-2026", 
#   active: true,
#   batch: batch
# )

# skill_block_titles = [
#   "Identification d'un questionnement au sein d'un champ disciplinaire",
#   "Analyse d'un questionnement en mobilisant des concepts disciplinaires",
#   "Mise en oeuvre de méthodes et d'outils du champ disciplinaire",
#   "Usages digitaux et numériques",
#   "Exploitation de données à des fins d'analyse",
#   "Expression et communication écrites et orales",
#   "Positionnement vis-à-vis d'un champ professionnel",
#   "Action en responsabilité au sein d'une organisation professionnelle",
#   "Approches durables des techniques"
# ]

# skill_block_titles.each_with_index do |title, index|
#   SkillBlock.create!(
#     title: title, 
#     position: index + 1,
#     referential: ref
#   )
# end

# skills = [
#   [ 1, 3, "Identifier les principales familles de matériaux et leurs propriétés."],
#   [ 1, 3, "Mobiliser des concepts en mathématiques, en physique, en chimie, en thermodynamique, afin d'aborder des problèmes spécifiques aux différents domaines industriels."],
#   [ 2, 3, "Identifier le rôle et le champ d'application des sciences pour l'ingénieur dans tous les secteurs : milieux naturels, milieux industriels, transports, environnements urbains, etc.."],
#   [ 3, 3, "Valider un modèle par comparaison de ses prévisions aux résultats expérimentaux et apprécier ses limites de validité."],
#   [ 3, 3, "Mobiliser les outils mathématiques nécessaires à la modélisation."],
#   [ 3, 3, "Estimer les ordres de grandeur et manipuler correctement les unités."],
#   [ 3, 3, "Intégrer une vision correcte de l'espace et de ses représentations."],
#   [ 3, 3, "Isoler un système."],
#   [ 3, 3, "Mettre en oeuvre des techniques d'algorithmique et de programmation, notamment pour développer des applications simples d'acquisition et de traitements de données."],
#   [ 4, 3, "Utiliser les outils numériques de référence et les règles de sécurité informatique pour acquérir, traiter, produire et diffuser de l'information ainsi que pour collaborer en interne et en externe."],
#   [ 5, 3, "Identifier, sélectionner et analyser avec esprit critique diverses ressources dans son domaine de spécialité pour documenter un sujet et synthétiser ces données en vue de leur exploitation."],
#   [ 5, 3, "Analyser et synthétiser des données en vue de leur exploitation."],
#   [ 5, 3, "Développer une argumentation avec esprit critique."],
#   [ 6, 3, "Se servir aisément des différents registres d'expression écrite et orale de la langue française."],
#   [ 6, 0, "Communiquer par oral et par écrit, de façon claire et non-ambiguë, dans au moins une langue étrangère."],
#   [ 7, 3, "Identifier et situer les champs professionnels potentiellement en relation avec les acquis de la mention ainsi que les parcours possibles pour y accéder."],
#   [ 7, 3, "Caractériser et valoriser son identité, ses compétences et son projet professionnel en fonction d'un contexte."],
#   [ 7, 3, "Identifier le processus de production, de diffusion et de valorisation des savoirs."],
#   [ 8, 3, "Situer son rôle et sa mission au sein d'une organisation pour s'adapter et prendre des initiatives."],
#   [ 8, 3, "Respecter les principes d'éthique, de déontologie et de responsabilité environnementale."],
#   [ 8, 3, "Travailler en équipe et en réseau ainsi qu'en autonomie et responsabilité au service d'un projet."],
#   [ 8, 3, "Analyser ses actions en situation professionnelle, s'autoévaluer pour améliorer sa pratique."],
#   [ 8, 3, "S'appuyer sur la pensée critique et faire preuve de réflexivité."],
#   [ 9, 3, "Etre en mesure d'évaluer et identifier des solutions pour réduire les impacts environnementaux des techniques."],
#   [ 9, 3, "Articuler les savoir-faire de différents champs disciplinaires dans un contexte de décision ou d'action."],
#   [ 9, 3, "Maitriser les outils d'évaluation multicritères et transformer les outils existants."],
#   [ 9, 3, "Adopter une approche systémique."],
#   [ 9, 3, "Comprendre les scenarios existants et être capable d'engager une démarche prospective."],
#   [ 9, 3, "Tenir compte des risques et incertitudes dans les scénarios."]
# ]
																																	
# skills.each_with_index do |skill, index|
#   Skill.create!(
#     title: skill[2], 
#     position: index + 1,
#     skill_block: SkillBlock.find_by(position: skill[0]), 
#     evaluated: skill[1]
#   )
# end

# batch = Batch.create!(
#   title: "L-STES 2025-2026",
#   discord_server_id: "1418791289377390686",
#   discord_invite_url: "https://discord.gg/z3GmuyMb"
# ) 

# ref = Referential.create!(
#   title: "L-STES 2025-2026", 
#   active: true,
#   batch: batch
# )

# skill_block_titles = [
#   "APPRENDRE POUR COMPRENDRE : Appréhender les enjeux liés aux Transitions de façon systémique",
#   "COMPRENDRE POUR AGIR : Acquérir les outils, les méthodes pour la conduite du changement",
#   "AGIR POUR CONSTUIRE : Se projeter vers son avenir personnel, professionnel et citoyen"
# ]

# skill_block_titles.each_with_index do |title, index|
#   SkillBlock.create!(
#     title: title, 
#     position: index + 1,
#     referential: ref
#   )
# end

# skills = [
#   [ 1, 3, "En mobilisant les connaissances et les concepts fondamentaux pour la compréhension globale des Transitions"],
#   [ 1, 3, "En comprenant les enjeux des transitions spécifiques aux territoires multi-insulaires (risques et opportunités)."],
#   [ 1, 3, "En développant une vision transdisciplinaire et multiculturelle pour appréhender un système complexe"],
#   [ 1, 3, "En recherchant et en mobilisant diverses ressources de manière critique et contextualisée pour répondre à une problématique"],
#   [ 1, 3, "En identifiant la place des savoirs traditionnels dans la préservation de l’environnement"],
#   [ 1, 3, "En synthétisant des données pertinentes à des fins d’analyse et d’explication des phénomènes"],
#   [ 1, 3, "En analysant un cahier des charges, un bilan, un rapport d’études en mobilisant les concepts et les technologies/outils liés au développement durable et/ou à l’aménagement des territoires"],
#   [ 1, 3, "En appliquant une démarche prospective appliquée aux transitions dans les territoires multi-insulaires"],
#   [ 1, 3, "En évaluant les impacts sur le développement durable d’un produit, d’un service et/ou d’un projet de territoire"],
#   [ 2, 3, "En adoptant des pratiques de travail collaboratif et individuel pour mener les Transitions "],
#   [ 2, 3, "En s’exprimant et en communiquant à l’oral et à l’écrit dans un environnement multiculturel"],
#   [ 2, 3, "En concevant des projets et des actions adaptés aux besoins du territoire"],
#   [ 2, 3, "En conduisant et en gérant des projets liés aux transitions"],
#   [ 2, 3, "En élaborant des récits inspirants et des argumentaires convaincants"],
#   [ 2, 3, "En s’appropriant les outils d’aide à la décision (IA, BU, géomatique, Statistiques, bilan carbone...)"],
#   [ 3, 3, "En respectant les principes d’éthique, de déontologie et de responsabilité (sociale, environnementale…)"],
#   [ 3, 3, "En identifiant les champs professionnels à forte durabilité"],
#   [ 3, 3, "En approfondissant ses compétences en créativité, innovation, gestion de projet et entrepreneuriat"],
#   [ 3, 3, "En s'orientant dans le système des responsabilités au service de la durabilité"],
#   [ 3, 3, "En valorisant ses capacités spécifiques aux TEMMI au sein d’un réseau professionnel local ou international (stages, cv, prises de parole)"]
# ]
																																	
# skills.each_with_index do |skill, index|
#   Skill.create!(
#     title: skill[2], 
#     position: index + 1,
#     skill_block: Batch.last.referentials.last.skill_blocks.find_by(position: skill[0]), 
#     evaluated: skill[1]
#   )
# end

# Project.create!(
#   batch: Batch.last,
#   name: "Cegelec", 
#   description: "Cegelec",  
#   subject: :stes, 
#   max_booking: 1, 
#   author: 'Caroline DESBOIS-DALMON', 
#   active: true
# )

# Project.create!(
#   batch: Batch.last,
#   name: "AOA Polynésien Forests", 
#   description: "AOA Polynésien Forests",  
#   subject: :stes, 
#   max_booking: 1, 
#   author: 'Caroline DESBOIS-DALMON', 
#   active: true
# )

# Project.create!(
#   batch: Batch.last,
#   name: "Ressourcerie", 
#   description: "Ressourcerie",  
#   subject: :stes, 
#   max_booking: 1, 
#   author: 'Caroline DESBOIS-DALMON', 
#   active: true
# )

# Project.create!(
#   batch: Batch.last,
#   name: "Intercontinental", 
#   description: "Intercontinental",  
#   subject: :stes, 
#   max_booking: 1, 
#   author: 'Caroline DESBOIS-DALMON', 
#   active: true
# )

# Project.create!(
#   batch: Batch.last,
#   name: "Réseau UniC", 
#   description: "Réseau UniC",  
#   subject: :stes, 
#   max_booking: 1, 
#   author: 'Caroline DESBOIS-DALMON', 
#   active: true
# )

# Project.create!(
#   batch: Batch.last,
#   name: "Lentille d’eau", 
#   description: "Lentille d’eau",  
#   subject: :stes, 
#   max_booking: 1, 
#   author: 'Caroline DESBOIS-DALMON', 
#   active: true
# )

# Project.create!(
#   batch: Batch.last,
#   name: "Fenuama", 
#   description: "Fenuama",  
#   subject: :stes, 
#   max_booking: 1, 
#   author: 'Caroline DESBOIS-DALMON', 
#   active: true
# )

# b = Batch.find_by(title: "LSPI 2025-2028")
# b.update(discord_invite_url: "https://discord.gg/79d2K6CZ")

# Project.create!(
#   batch: 3,
#   name: "BIOPACKAGING : Développement de matériaux BIO-SOURCES ET BIODEGRADABLE pour CONTENANT alimentaire en Polynésie", 
#   description: "Contexte : La pollution plastique représente un enjeu environnemental majeur à l'échelle mondiale, particulièrement critique dans les écosystèmes insulaires fragiles comme la Polynésie française. Face à ce constat, une Loi du Pays (LOI DU PAYS n° 26-2024) a été votée pour interdire progressivement les contenants alimentaires à usage unique non dégradables à partir de 2026. Cela crée une urgence et un besoin de trouver des alternatives durables, locales et économiquement viables. Ce projet s'inscrit directement dans cette démarche en proposant une solution basée sur l'économie circulaire : valoriser des déchets agricoles ou autres ressources abondantes pour créer de la valeur, tout en répondant à un besoin essentiel de l'industrie alimentaire. Il donnera aux étudiants l'occasion de devenir des acteurs de l'innovation et du développement durable sur leur propre territoire.",  
#   subject: :stes, 
#   max_booking: 3, 
#   author: 'Jeremy Yune', 
#   active: true
# )

# [{:id=>342, :progress=>"booked"},
#  {:id=>343, :progress=>"booked"},
#  {:id=>302, :progress=>"booked"},
#  {:id=>307, :progress=>"booked"},
#  {:id=>316, :progress=>"booked"},
#  {:id=>306, :progress=>"booked"},
#  {:id=>318, :progress=>"booked"},
#  {:id=>303, :progress=>"booked"},
#  {:id=>304, :progress=>"booked"},
#  {:id=>345, :progress=>"booked"},
#  {:id=>321, :progress=>"booked"},
#  {:id=>301, :progress=>"booked"},
#  {:id=>305, :progress=>"booked"},
#  {:id=>313, :progress=>"booked"},
#  {:id=>320, :progress=>"booked"},
#  {:id=>317, :progress=>"booked"},
#  {:id=>326, :progress=>"booked"},
#  {:id=>328, :progress=>"booked"},
#  {:id=>309, :progress=>"booked"},
#  {:id=>308, :progress=>"booked"},
#  {:id=>332, :progress=>"booked"},
#  {:id=>310, :progress=>"booked"},
#  {:id=>319, :progress=>"booked"},
#  {:id=>312, :progress=>"booked"},
#  {:id=>314, :progress=>"booked"},
#  {:id=>330, :progress=>"booked"},
#  {:id=>329, :progress=>"booked"},
#  {:id=>337, :progress=>"booked"},
#  {:id=>331, :progress=>"booked"},
#  {:id=>335, :progress=>"booked"},
#  {:id=>334, :progress=>"booked"},
#  {:id=>369, :progress=>"booked"},
#  {:id=>339, :progress=>"booked"},
#  {:id=>336, :progress=>"booked"},
#  {:id=>341, :progress=>"booked"},
#  {:id=>338, :progress=>"booked"},
#  {:id=>340, :progress=>"booked"}]

#  b_ids = [ 342, 343, 302, 307, 316, 306, 318, 303, 304, 345, 321, 301, 305, 313, 320, 317, 326, 328, 
#    309, 308, 332, 310, 319, 312, 314, 330, 329, 337, 331, 335, 334, 369, 339, 336, 341, 338, 340]


# b.projects
# p = b.projects.find(46)
# users= []

# u = b.users.find_by(first_name: "")

# users << u

# t = Team.new(name: p.name, project: p, user: users.first)
# t.save

# users.each{|u| u.update(team: t)}


####################


batch = Batch.create!(
  title: "L1-STES 2025-2026",
  discord_server_id: "1418791289377390686",
  discord_invite_url: "https://discord.gg/z3GmuyMb"
) 

ref = Referential.create!(
  title: "L1-STES 2025-2026", 
  active: true,
  batch: batch
)

skill_block_titles = [
  "APPRENDRE POUR COMPRENDRE : Appréhender les enjeux liés aux Transitions de façon systémique",
  "COMPRENDRE POUR AGIR : Acquérir les outils, les méthodes pour la conduite du changement",
  "AGIR POUR CONSTUIRE : Se projeter vers son avenir personnel, professionnel et citoyen"
]

skill_block_titles.each_with_index do |title, index|
  SkillBlock.create!(
    title: title, 
    position: index + 1,
    referential: ref
  )
end

skills = [
  [ 1, 3, "En mobilisant les connaissances et les concepts fondamentaux pour la compréhension globale des Transitions"],
  [ 1, 3, "En comprenant les enjeux des transitions spécifiques aux territoires multi-insulaires (risques et opportunités)."],
  [ 1, 3, "En développant une vision transdisciplinaire et multiculturelle pour appréhender un système complexe"],
  [ 1, 3, "En recherchant et en mobilisant diverses ressources de manière critique et contextualisée pour répondre à une problématique"],
  [ 1, 3, "En identifiant la place des savoirs traditionnels dans la préservation de l’environnement"],
  [ 1, 3, "En synthétisant des données pertinentes à des fins d’analyse et d’explication des phénomènes"],
  [ 1, 3, "En analysant un cahier des charges, un bilan, un rapport d’études en mobilisant les concepts et les technologies/outils liés au développement durable et/ou à l’aménagement des territoires"],
  [ 1, 3, "En appliquant une démarche prospective appliquée aux transitions dans les territoires multi-insulaires"],
  [ 1, 3, "En évaluant les impacts sur le développement durable d’un produit, d’un service et/ou d’un projet de territoire"],
  [ 2, 3, "En adoptant des pratiques de travail collaboratif et individuel pour mener les Transitions "],
  [ 2, 3, "En s’exprimant et en communiquant à l’oral et à l’écrit dans un environnement multiculturel"],
  [ 2, 3, "En concevant des projets et des actions adaptés aux besoins du territoire"],
  [ 2, 3, "En conduisant et en gérant des projets liés aux transitions"],
  [ 2, 3, "En élaborant des récits inspirants et des argumentaires convaincants"],
  [ 2, 3, "En s’appropriant les outils d’aide à la décision (IA, BU, géomatique, Statistiques, bilan carbone...)"],
  [ 3, 3, "En respectant les principes d’éthique, de déontologie et de responsabilité (sociale, environnementale…)"],
  [ 3, 3, "En identifiant les champs professionnels à forte durabilité"],
  [ 3, 3, "En approfondissant ses compétences en créativité, innovation, gestion de projet et entrepreneuriat"],
  [ 3, 3, "En s'orientant dans le système des responsabilités au service de la durabilité"],
  [ 3, 3, "En valorisant ses capacités spécifiques aux TEMMI au sein d’un réseau professionnel local ou international (stages, cv, prises de parole)"]
]
																																	
skills.each_with_index do |skill, index|
  Skill.create!(
    title: skill[2], 
    position: index + 1,
    skill_block: SkillBlock.find_by(position: skill[0], referential: Referential.last), 
    evaluated: skill[1]
  )
end

p1 = Project.create!(
  batch: Batch.last,
  name: "Réalisation d'une boite pédagogique (ou d'un livret d'information) sur le compostage en Polynésie", 
  description: "Depuis plusieurs années, Nīnamu Solutions mène des actions de sensibilisation et de formation au compostage en Polynésie, notamment auprès des écoles, des associations et des collectivités. Ces expériences de terrain ont mis en évidence un réel intérêt pour la thématique du compostage, mais aussi un manque d’outils pédagogiques ludiques, concrets et réellement adaptés au contexte polynésien.
L’objectif de ce projet est donc de réfléchir à la création d’une boîte pédagogique sur le compostage, pensée comme un outil clé en main, utilisable par des personnes formées, afin de faciliter et de multiplier les actions de sensibilisation sur le territoire.
",  
  subject: :stes, 
  max_booking: 1, 
  author: 'Ninamu Solutions', 
  active: true
)

p2 = Project.create!(
  batch: Batch.last,
  name: "Rechargement Solaire des Véhicules Electriques : Installation de panneaux photovoltaïques sur le parking du personnel de l’UPF ", 
  description: "
    Ce projet s’inscrit dans la démarche de transition énergétique portée par l’UPF. Il vise à contribuer à la décarbonation des trajets domicile-travail du personnel de l’université. En effet, l’UPF compte plus de XXX salariés qui se rendent quotidiennement sur le campus, ce qui pèse significativement sur son bilan carbone. Plusieurs agents pourraient souhaiter s’engager dans cette transition en investissant dans un véhicule électrique. Toutefois, l’intérêt environnemental de ce dernier n’est pleinement réalisé que lorsqu’il est alimenté par une énergie renouvelable. Or, le personnel étant présent sur le campus durant la journée, la recharge des véhicules s’effectue le plus souvent le soir à domicile, sur un réseau encore majoritairement alimenté par des centrales au fioul, ce qui en limite fortement l’impact positif.
  ",  
  subject: :stes, 
  max_booking: 1, 
  author: 'UPF', 
  active: true
)

p3 = Project.create!(
  batch: Batch.last,
  name: "Accompagner l’entreprise dans la sensibilisation de son personnel aux transitions et la promotion de pratiques durables, en s’appuyant sur les résultats de l’audit RSE AFNOR et les enjeux climatiques en Polynésie française.", 
  description: "Dans une dynamique de transition environnementale et sociétale, Cegelec Polynésie souhaite renforcer sa culture interne autour des enjeux du développement durable. À la suite de son dernier audit RSE réalisé par le Label Engagé AFNOR, l’entreprise a identifié des leviers d’amélioration et des points forts à pérenniser. Ce projet tutoré s’inscrit dans cette volonté de transformation, en mobilisant les étudiants autour d’une mission concrète : accompagner l’entreprise dans la sensibilisation de ses collaborateurs aux transitions, tout en valorisant ses engagements et en favorisant l’émergence de pratiques durables au quotidien.",  
  subject: :stes, 
  max_booking: 1, 
  author: 'Cegelec', 
  active: true
)

p4 = Project.create!(
  batch: Batch.last,
  name: "Organisation d’une journée technique agronomique & REX destiné aux agriculteurs clients potentiels", 
  description: "Dans le cadre du projet d’« essais agronomiques » portés par TECHNIVAL, il est prévu l’organisation de journées techniques : visite des installations de valorisation des déchets verts de TECHNIVAL, visite d’une exploitation agricole partenaire, temps d’échanges…",  
  subject: :stes, 
  max_booking: 1, 
  author: 'Technival', 
  active: true
)

p5 = Project.create!(
  batch: Batch.last,
  name: "Réalisation de capsules video de témoignages de porteurs de projets sur la possibilité d’intégrer de manière simple et accessible, des actions écoresponsables dans leur activité professionnelle ", 
  description: "Dans un monde où la transition écologique devient un enjeu majeur, il est essentiel d’accompagner les professionnels vers des pratiques plus durables. 
Ce projet vise à réaliser des capsules vidéos d’interviews par lequel les entrepreneurs témoigneront la possibilité d’intégrer des actions écoresponsables dans leur activité professionnelle de manière simple et accessible. 
L’objectif est d’offrir un accompagnement pertinent et concret, permettant aux professionnels de mieux comprendre les enjeux environnementaux et d’agir efficacement dans leur domaine.
",  
  subject: :stes, 
  max_booking: 1, 
  author: 'ADIE', 
  active: true
)

p6 = Project.create!(
  batch: Batch.last,
  name: "Préparation Semaine d'intégration ", 
  description: "La rentrée à l’université est un moment crucial pour tout nouveau bachelier. La semaine d’intégration a pour vocation de faciliter l’entrée des nouveaux étudiants en première année de la licence STES, avec ses deux parcours, de créer de la cohésion au sein des promotions et de renforcer leur insertion sociale dans le campus. C’est également – et avant tout – l’occasion pour eux d’avoir une première approche, par la pratique, des grands défis environnementaux et sociaux ainsi que des 17 ODD de l’ONU. ",  
  subject: :stes, 
  max_booking: 1, 
  author: 'UPF', 
  active: true
)

p7 = Project.create!(
  batch: Batch.last,
  name: "Nudger tri sélectif à l'UPF", 
  description: "Le tri des déchets n’est pas effectué actuellement par les étudiants sur le campus, l’objectif est de dynamiser cette pratique en mettant en place de nouveaux affichages inspirés de la théorie de la rationalité limitée.",  
  subject: :stes, 
  max_booking: 1, 
  author: 'UPF', 
  active: true
)

p8 = Project.create!(
  batch: Batch.last,
  name: "Mesurer l'acceptabilité d’une solution technique qui rendrait potable et bénéfique à la consommation l’eau présente dans les atolls  (Lentille eau/SPI)", 
  description: "La licence SPI, comme la licence STES, intègre la méthodologie projet et les projets étudiants dans ses enseignements. En partenariat avec le groupe d’écoles Polytech, les étudiants L1 SPI mènent un projet visant à améliorer des systèmes existant d’osmoseurs afin de pouvoir les utiliser dans les atolls afin et rendre potable et favorable à la consommation (donc également suffisamment minéralisée) l’eau présente sur site. 
Les étudiants de L1 SPI ont commencé en S1 à faire un état lieu de l’existant technique et des potentiels.
En vue de mutualiser les compétences des SPI et des STES, et à partir de l’état des lieux réalisé par la SPI, il est proposé un groupe de L1 STES de mesurer l’acceptabilité des populations ciblées pour une solution de transformation de l’eau présente dans les atolls afin de la rendre potable. ",  
  subject: :stes, 
  max_booking: 1, 
  author: 'UPF', 
  active: true
)

[p2, p3, p4, p5, p6, p7, p8].each do |p|
  Supervision.create!(
    project: p,
    user: User.find_by(email: "jonathan.serafini@gmail.com")
  )
end

Team.create!(name: "En attente de projet", user: User.find_by(email: "jonathan.serafini@gmail.com"))
