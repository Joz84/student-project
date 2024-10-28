Attempt.destroy_all
Exercice.destroy_all
Ticket.destroy_all
Course.destroy_all
Card.destroy_all
List.destroy_all
Team.destroy_all
Rating.destroy_all
Project.destroy_all
User.destroy_all

User.create!(admin: true, email: "dev@mihivai.com", password: 'azerty', first_name: "Dev", last_name: "Upf", student_number: 1, teacher: true, cw_nickname: "")  
User.create!(email: "student@gmail.com", password: 'azerty', first_name: "Bob", last_name: "Upf", student_number: 2)

Project.create!(
  name: "Totem", 
  description: " Réalisation d’un boitier de collecte de données sur un support (totem) pour évaluer la
performance de bâtiments portant sur les conditions de confort, la qualité de l’air (IAQ), la santé
cognitive des occupants et les consommations électriques. Ce totem sera basé sur l’utilisation de
technologies (capteurs, contrôleurs) low cost et la réalisation de pièces par imprimante 3D.", 
  subject: :physique, 
  max_booking: 4, 
  author: 'Franck Lucas', 
  active: true
)

Project.create!(
  name: "Robot Tiki", 
  description: "L'objectif principal de ce projet est de concevoir et construire un robot innovant capable de se mouvoir sur deux roues tout en maintenant son équilibre, grâce à un système de stabilisation utilisant un gyroscope connecté à un processeur Arduino. Ce robot, original par sa capacité à s’équilibrer et à se déplacer en autonomie, constitue une plateforme idéale pour expérimenter et appliquer des compétences pluridisciplinaires des sciences de l'ingénieur.", 
  subject: :physique, 
  max_booking: 4, 
  author: 'Franco Ferrucci', 
  active: true
)

Project.create!(
  name: "Station Météo", 
  description: "Concevoir et réaliser une station météorologique intelligente basée sur un microcontrôleur (Arduino) et des capteurs low-cost. La station collectera des données météorologiques locales, visant à créer un réseau de stations low-cost pour compléter et enrichir les réseaux météorologiques existants.", 
  subject: :physique, 
  max_booking: 4, 
  author: 'Jonathan Serafini', 
  active: true
)

Project.create!(
  name: "Hydroponie", 
  description: "Réalisation d’installations de culture hydroponique (voir figure ci-dessous) intégrant une
gestion et une collecte de données permettant l’automatisation d’apport en nutriment ainsi qu’en
eau. L’alimentation se fera en prenant en compte l’environnement extérieur, les nutriments présents
dans un réservoir d’eau afin d’en améliorer la production végétale et organique des aliments ainsi
que des consommations d’énergie. Ce système sera basé sur l’utilisation de technologies (capteurs,
contrôleurs) low cost et la réalisation de pièces par imprimante 3D.", 
  subject: :physique, 
  max_booking: 4, 
  author: 'Anthony Utahia', 
  active: true
)

Project.create!(
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
  name: "Chimie Extramet", 
  description: "Apprendre et maîtriser diverses techniques d’extraction de substances naturelles en utilisant des solvants variés (eau, éthanol, acétone).
Calculer les rendements d’extraction et les comparer pour chaque solvant et chaque échantillon étudié.
Utiliser la loi de Beer-Lambert pour quantifier les substances extraites par spectrophotométrie.
Comparer la concentration d’une substance naturelle extraite à partir d'une source terrestre ou marine avec un produit commercial similaire.
Maîtriser la démarche expérimentale complète depuis la préparation des extraits jusqu’à leur caractérisation quantitative.", 
  subject: :chimie, 
  max_booking: 1, 
  author: 'Raimana Ho', 
  active: true
)

Team.create!(name: "Les cocos", project: Project.first) 

Card.create!(
  name: "Se documenter", 
  description: "Il faut se documenter sur le sujet pour comprendre les enjeux et les contraintes du projet.", 
  list: List.first
)

cours1 = Course.create!(
  slides_link:  "https://docs.google.com/presentation/d/e/2PACX-1vS1R7VMYHQpITtnmw3KhmBNKfuNYY0btAxaSvvQgtnAs-stnSgNcEAW-XkXm4oXeLucyP87eyLCKszs/embed?start=false&loop=false&delayms=3000", 
  position: 1, 
  ticket_activation: true, 
  name: "Introduction à Python"
)

cours2 = Course.create!(
  slides_link:  "https://docs.google.com/presentation/d/e/2PACX-1vS1R7VMYHQpITtnmw3KhmBNKfuNYY0btAxaSvvQgtnAs-stnSgNcEAW-XkXm4oXeLucyP87eyLCKszs/embed?start=false&loop=false&delayms=3000", 
  position: 2, 
  ticket_activation: false, 
  name: "Les listes et les boucles"
)

cours3 = Course.create!(
  slides_link:  "https://docs.google.com/presentation/d/e/2PACX-1vS1R7VMYHQpITtnmw3KhmBNKfuNYY0btAxaSvvQgtnAs-stnSgNcEAW-XkXm4oXeLucyP87eyLCKszs/embed?start=false&loop=false&delayms=3000", 
  position: 3, 
  ticket_activation: false, 
  name: "Les dictionnaires"
)

# Ticket.create!(user: User.last, content: "Ca marche pas!")
# Ticket.create!(user: User.last, content: "Ca marche tjr pas!")
# Exercice.create!(name: "Find the position2!", cw_token: "5808e2006b65bff35500008f", position: 1, course: Course.last, kata: 8)
# Exercice.create!(name: "Double Char2", cw_token: "56b1f01c247c01db92000076", position: 2, course: Course.last, kata: 8)

Exercice.create!(
  name: "Hello, Name or World!", 
  cw_token: "57e3f79c9cb119374600046b", 
  position: 1, 
  course: cours1, 
  kata: 8,
  description: "## Description

Définir une fonction `hello` qui retourne `\"Hello, Name!\"` pour un `name` donné.
Elle affiche `\"Hello, World!\"` si `name` n'est pas donné (ou passé comme chaîne de caractères vide).

On suppose que `name` est une chaîne de caractères (`String`). 
Cette chaîne de caractères peut contenir des fautes de frappe de l'utilisateur.
La fonction les corrigera en retournant toujours un nom avec une première lettre en majuscule (`Xxxx`).

### Exemples :

* Avec `name = \"john\"`  
  ➔ return `\"Hello, John!\"`

* Avec `name = \"aliCE\"`  
  ➔ return `\"Hello, Alice!\"`

* Si `name` n'est pas fourni  
  ou `name = \"\"`  
  ➔ return `\"Hello, World!\"`
"
)

Exercice.create!(
  name: "Area or Perimeter", 
  cw_token: "5ab6538b379d20ad880000ab", 
  position: 2, 
  course: cours1, 
  kata: 8,
  description: "## Description

On vous donne la `longueur` et la `largeur` d'un polygone à 4 côtés. Le polygone peut être un rectangle ou un carré.  
S'il s'agit d'un carré, retournez son aire. S'il s'agit d'un rectangle, retournez son périmètre.

### Exemple (Entrée1, Entrée2 --> Sortie) :

```
* 6, 10 --> 32
* 3, 3 --> 9
```

**Remarque** : pour les besoins de cet exercice, vous supposerez qu'il s'agit d'un carré si sa `longueur` et sa `largeur` sont égales, sinon il s'agit d'un rectangle."
)

Exercice.create!(
  name: "Keep Hydrated!", 
  cw_token: "582cb0224e56e068d800003c", 
  position: 3, 
  course: cours1, 
  kata: 8,
  description: "## Description

Nathan adore faire du vélo.

Comme Nathan sait qu'il est important de rester hydraté, il boit 0,5 litre d'eau par heure de vélo.

On vous donne le temps en heures et vous devez renvoyer le nombre de litres que Nathan boira, arrondi à la valeur la plus petite.

### Exemple :

```
* time = 3 ----> litres = 1

* time = 6.7---> litres = 3

* time = 11.8--> litres = 5
```
"
)

Exercice.create!(
  name: "Is the string uppercase?", 
  cw_token: "56cd44e1aa4ac7879200010b", 
  position: 4, 
  course: cours1, 
  kata: 8,
  description: "## Description

Créez une méthode pour voir si la chaîne est EN MAJUSCULES.

### Exemple (Entrée -> Sortie) :

```
*\"c\" -> False
*\"C\" -> True
*\"hello I AM DONALD\" -> False
*\"HELLO I AM DONALD\" -> True
*\"ACSKLDFJSgSKLDFJSKLDFJ\" -> False
*\"ACSKLDFJSGSKLDFJSKLDFJ\" -> True
```

**Remarque** : Dans ce Kata, une chaîne est dite en MAJUSCULES lorsqu'elle ne contient aucune lettre minuscule, donc toute chaîne ne contenant aucune lettre est trivialement considérée comme étant en MAJUSCULES.
"
)

