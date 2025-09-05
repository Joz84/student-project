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

# Project.create!(
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
#   name: "Robot Tiki", 
#   description: "L'objectif principal de ce projet est de concevoir et construire un robot innovant capable de se mouvoir sur deux roues tout en maintenant son équilibre, grâce à un système de stabilisation utilisant un gyroscope connecté à un processeur Arduino. Ce robot, original par sa capacité à s'équilibrer et à se déplacer en autonomie, constitue une plateforme idéale pour expérimenter et appliquer des compétences pluridisciplinaires des sciences de l'ingénieur.", 
#   subject: :physique, 
#   max_booking: 4, 
#   author: 'Franco Ferrucci', 
#   active: true
# )

# Project.create!(
#   name: "Station Météo", 
#   description: "Concevoir et réaliser une station météorologique intelligente basée sur un microcontrôleur (Arduino) et des capteurs low-cost. La station collectera des données météorologiques locales, visant à créer un réseau de stations low-cost pour compléter et enrichir les réseaux météorologiques existants.", 
#   subject: :physique, 
#   max_booking: 4, 
#   author: 'Jonathan Serafini', 
#   active: true
# )

# Project.create!(
#   name: "Hydroponie", 
#   description: "Réalisation d'installations de culture hydroponique (voir figure ci-dessous) intégrant une
# gestion et une collecte de données permettant l'automatisation d'apport en nutriment ainsi qu'en
# eau. L'alimentation se fera en prenant en compte l'environnement extérieur, les nutriments présents
# dans un réservoir d'eau afin d'en améliorer la production végétale et organique des aliments ainsi
# que des consommations d'énergie. Ce système sera basé sur l'utilisation de technologies (capteurs,
# contrôleurs) low cost et la réalisation de pièces par imprimante 3D.", 
#   subject: :physique, 
#   max_booking: 4, 
#   author: 'Anthony Utahia', 
#   active: true
# )

# Project.create!(
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

# Team.create!(name: "Les cocos", project: Project.first) 

# Card.create!(
#   name: "Se documenter", 
#   description: "Il faut se documenter sur le sujet pour comprendre les enjeux et les contraintes du projet.", 
#   list: List.first
# )

# cours1 = Course.create!(
#   slides_link:  "https://docs.google.com/presentation/d/e/2PACX-1vS1R7VMYHQpITtnmw3KhmBNKfuNYY0btAxaSvvQgtnAs-stnSgNcEAW-XkXm4oXeLucyP87eyLCKszs/embed?start=false&loop=false&delayms=3000", 
#   position: 1, 
#   ticket_activation: true, 
#   name: "Introduction à Python"
# )

# cours2 = Course.create!(
#   slides_link:  "https://docs.google.com/presentation/d/e/2PACX-1vS1R7VMYHQpITtnmw3KhmBNKfuNYY0btAxaSvvQgtnAs-stnSgNcEAW-XkXm4oXeLucyP87eyLCKszs/embed?start=false&loop=false&delayms=3000", 
#   position: 2, 
#   ticket_activation: false, 
#   name: "Les listes et les boucles"
# )

# cours3 = Course.create!(
#   slides_link:  "https://docs.google.com/presentation/d/e/2PACX-1vS1R7VMYHQpITtnmw3KhmBNKfuNYY0btAxaSvvQgtnAs-stnSgNcEAW-XkXm4oXeLucyP87eyLCKszs/embed?start=false&loop=false&delayms=3000", 
#   position: 3, 
#   ticket_activation: false, 
#   name: "Les dictionnaires"
# )

# # Ticket.create!(user: User.last, content: "Ca marche pas!")
# # Ticket.create!(user: User.last, content: "Ca marche tjr pas!")
# # Exercice.create!(name: "Find the position2!", cw_token: "5808e2006b65bff35500008f", position: 1, course: Course.last, kata: 8)
# # Exercice.create!(name: "Double Char2", cw_token: "56b1f01c247c01db92000076", position: 2, course: Course.last, kata: 8)

# Exercice.create!(
#   name: "Hello, Name or World!", 
#   cw_token: "57e3f79c9cb119374600046b", 
#   position: 1, 
#   course: cours1, 
#   kata: 8,
#   description: "## Description

# Définir une fonction `hello` qui retourne `\"Hello, Name!\"` pour un `name` donné.
# Elle affiche `\"Hello, World!\"` si `name` n'est pas donné (ou passé comme chaîne de caractères vide).

# On suppose que `name` est une chaîne de caractères (`String`). 
# Cette chaîne de caractères peut contenir des fautes de frappe de l'utilisateur.
# La fonction les corrigera en retournant toujours un nom avec une première lettre en majuscule (`Xxxx`).

# ### Exemples :

# * Avec `name = \"john\"`  
#   ➔ return `\"Hello, John!\"`

# * Avec `name = \"aliCE\"`  
#   ➔ return `\"Hello, Alice!\"`

# * Si `name` n'est pas fourni  
#   ou `name = \"\"`  
#   ➔ return `\"Hello, World!\"`
# "
# )

# Exercice.create!(
#   name: "Area or Perimeter", 
#   cw_token: "5ab6538b379d20ad880000ab", 
#   position: 2, 
#   course: cours1, 
#   kata: 8,
#   description: "## Description

# On vous donne la `longueur` et la `largeur` d'un polygone à 4 côtés. Le polygone peut être un rectangle ou un carré.  
# S'il s'agit d'un carré, retournez son aire. S'il s'agit d'un rectangle, retournez son périmètre.

# ### Exemple (Entrée1, Entrée2 --> Sortie) :

# ```
# * 6, 10 --> 32
# * 3, 3 --> 9
# ```

# **Remarque** : pour les besoins de cet exercice, vous supposerez qu'il s'agit d'un carré si sa `longueur` et sa `largeur` sont égales, sinon il s'agit d'un rectangle."
# )

# Exercice.create!(
#   name: "Keep Hydrated!", 
#   cw_token: "582cb0224e56e068d800003c", 
#   position: 3, 
#   course: cours1, 
#   kata: 8,
#   description: "## Description

# Nathan adore faire du vélo.

# Comme Nathan sait qu'il est important de rester hydraté, il boit 0,5 litre d'eau par heure de vélo.

# On vous donne le temps en heures et vous devez renvoyer le nombre de litres que Nathan boira, arrondi à la valeur la plus petite.

# ### Exemple :

# ```
# * time = 3 ----> litres = 1

# * time = 6.7---> litres = 3

# * time = 11.8--> litres = 5
# ```
# "
# )

# Exercice.create!(
#   name: "Is the string uppercase?", 
#   cw_token: "56cd44e1aa4ac7879200010b", 
#   position: 4, 
#   course: cours1, 
#   kata: 8,
#   description: "## Description

# Créez une méthode pour voir si la chaîne est EN MAJUSCULES.

# ### Exemple (Entrée -> Sortie) :

# ```
# *\"c\" -> False
# *\"C\" -> True
# *\"hello I AM DONALD\" -> False
# *\"HELLO I AM DONALD\" -> True
# *\"ACSKLDFJSgSKLDFJSKLDFJ\" -> False
# *\"ACSKLDFJSGSKLDFJSKLDFJ\" -> True
# ```

# **Remarque** : Dans ce Kata, une chaîne est dite en MAJUSCULES lorsqu'elle ne contient aucune lettre minuscule, donc toute chaîne ne contenant aucune lettre est trivialement considérée comme étant en MAJUSCULES.
# "
# )

# Exercice.where(course: Course.find_by(position: 2)).destroy_all

# Exercice.create!(
#   name: "Return a string's even characters.", 
#   cw_token: "566044325f8fddc1c000002c", 
#   position: 1, 
#   course: Course.find_by(position: 2), 
#   kata: 7,
#   description: "## Description:
# Écrivez une fonction qui renvoie une séquence (l'index commence par 1) de tous les caractères pairs d'une chaîne. Si la chaîne contient moins de deux caractères ou plus de 100 caractères, la fonction doit renvoyer « chaîne non valide ».

# ### Exemples:

# ```
# \"abcdefghijklm\" --> [\"b\", \"d\", \"f\", \"h\", \"j\", \"l\"]
# ```

# ```
# \"a\"             --> \"invalid string\"
# ```
# "
# )

# Exercice.create!(
#   name: "Password maker", 
#   cw_token: "5637b03c6be7e01d99000046", 
#   position: 2, 
#   course: Course.find_by(position: 2), 
#   kata: 7,
#   description: "## Description:
# Une suggestion pour créer un mot de passe satisfaisant est de commencer par une phrase ou une expression mémorable et de créer un mot de passe en extrayant la première lettre de chaque mot.

# Il est encore mieux de remplacer certaines de ces lettres par des chiffres (par exemple, la lettre Opeut être remplacée par le chiffre 0) :

# au lieu d'inclure i ou I de mettre le numéro 1 dans le mot de passe ;
# au lieu d'inclure o ou O de mettre le numéro 0 dans le mot de passe ;
# au lieu d'inclure s ou S de mettre le numéro 5 dans le mot de passe.

# ### Exemples:

# ```
# \"Give me liberty or give me death\"  --> \"Gml0gmd\"
# ```

# ```
# \"Keep Calm and Carry On\"            --> \"KCaC0\"
# ```
# "
# )

# Exercice.create!(
#   name: "Password validator", 
#   cw_token: "56a921fa8c5167d8e7000053", 
#   position: 3, 
#   course: Course.find_by(position: 2), 
#   kata: 7,
#   description: "## Description
# Votre travail consiste à créer une fonction de validation de mot de passe simple, comme celle que l'on voit sur de nombreux sites Web.

# Les règles pour un mot de passe valide sont les suivantes :

# - Il doit y avoir au moins 1 lettre majuscule.
# - Il doit y avoir au moins 1 lettre minuscule.
# - Il doit y avoir au moins 1 numéro.
# - Le mot de passe doit comporter au moins 8 caractères.
# Vous êtes autorisé à utiliser toutes les méthodes pour valider le mot de passe.

# ### Exemples:
# ```
# password(\"Abcd1234\"); ===> true
# ```

# ```
# password(\"Abcd123\"); ===> false
# ```

# ```
# password(\"abcd1234\"); ===> false
# ```

# ```
# password(\"AbcdefGhijKlmnopQRsTuvwxyZ1234567890\"); ===> true
# ```

# ```
# password(\"ABCD1234\"); ===> false
# ```

# ```
# password(\"Ab1!@#$%^&*()-_+={}[]|\:;?/>.<,\"); ===> true;
# ```

# ```
# password(\"!@#$%^&*()-_+={}[]|\:;?/>.<,\"); ===> false;
# ```

# Informations supplémentaires
# - Seules des chaînes vous seront transmises.
# - La chaîne peut contenir n'importe quel caractère de clavier standard.
# - Les chaînes acceptées peuvent avoir n'importe quelle longueur, à condition qu'elles comportent 8 caractères ou plus.

# "
# )

# Exercice.create!(
#   name: "Sum of two lowest positive integers", 
#   cw_token: "558fc85d8fd1938afb000014", 
#   position: 4, 
#   course: Course.find_by(position: 2), 
#   kata: 7,
#   description: "## Description:
# Créez une fonction qui renvoie la somme des deux nombres positifs les plus bas à partir d'un tableau d'au moins 4 entiers positifs. Aucun nombre flottant ou entier non positif ne sera transmis.

# ### Exemples : (Entrée --> Sortie)

# ```
# [19, 5, 42, 2, 77] --> 7
# ```

# ```
# [10, 343445353, 3453445, 3453545353453] --> 3453455
# ```
# "
# )

# Exercice.create!(
#   name: "Testing 1-2-3", 
#   cw_token: "54bf85e3d5b56c7a05000cf9", 
#   position: 5, 
#   course: Course.find_by(position: 2), 
#   kata: 7,
#   description: "## Description:
# Votre équipe écrit un nouvel éditeur de texte sophistiqué et vous avez été chargé d'implémenter la numérotation des lignes.

# Écrivez une fonction qui prend une liste de chaînes et renvoie chaque ligne précédée du numéro correct.

# La numérotation commence à 1. Le format est n: string. Notez les deux points et l'espace entre les deux.

# ### Exemples : (Entrée --> Sortie)

# ```
# [] --> []
#  ```
 
#  ```
# [\"a\", \"b\", \"c\"] --> [\"1: a\", \"2: b\", \"3: c\"]
# ```
# "
# )

#---------------------------------

# Exercice.find_by(position: 1, course: Course.find_by(position: 1)).update!( 
#   description: "## Description

# Définir une fonction `hello` qui retourne `\"Hello, Name!\"` pour un `name` donné.
# Elle affiche `\"Hello, World!\"` si `name` n'est pas donné (ou passé comme chaîne de caractères vide).

# On suppose que `name` est une chaîne de caractères (`String`). 
# Cette chaîne de caractères peut contenir des fautes de frappe de l'utilisateur.
# La fonction les corrigera en retournant toujours un nom avec une première lettre en majuscule (`Xxxx`).

# ### Exemples :

# * Avec `name = \"john\"`  
#   ➔ return `\"Hello, John!\"`

# * Avec `name = \"aliCE\"`  
#   ➔ return `\"Hello, Alice!\"`

# * Si `name` n'est pas fourni  
#   ou `name = \"\"`  
#   ➔ return `\"Hello, World!\"`
# "
# )

# Exercice.find_by(position: 2, course: Course.find_by(position: 1)).update!( 
#   description: "## Description

# On vous donne la `longueur` et la `largeur` d'un polygone à 4 côtés. Le polygone peut être un rectangle ou un carré.  
# S'il s'agit d'un carré, retournez son aire. S'il s'agit d'un rectangle, retournez son périmètre.

# ### Exemple (Entrée1, Entrée2 --> Sortie) :

# ```
# 6, 10 --> 32
# ```

# ```
# 3, 3 --> 9
# ```

# **Remarque** : pour les besoins de cet exercice, vous supposerez qu'il s'agit d'un carré si sa `longueur` et sa `largeur` sont égales, sinon il s'agit d'un rectangle."
# )

# Exercice.find_by(position: 3, course: Course.find_by(position: 1)).update!( 
#   description: "## Description

# Nathan adore faire du vélo.

# Comme Nathan sait qu'il est important de rester hydraté, il boit 0,5 litre d'eau par heure de vélo.

# On vous donne le temps en heures et vous devez renvoyer le nombre de litres que Nathan boira, arrondi à la valeur la plus petite.

# ### Exemple :

# ```
# time = 3 ----> litres = 1
# ```

# ```
# time = 6.7---> litres = 3
# ```

# ```
# time = 11.8--> litres = 5
# ```
# "
# )

# Exercice.find_by(position: 4, course: Course.find_by(position: 1)).update!( 
#   description: "## Description

# Créez une méthode pour voir si la chaîne est EN MAJUSCULES.

# ### Exemple (Entrée -> Sortie) :

# ```
# \"c\" -> False
# ```

# ```
# \"C\" -> True
# ```

# ```
# \"hello I AM DONALD\" -> False
# ```

# ```
# \"HELLO I AM DONALD\" -> True
# ```

# ```
# \"ACSKLDFJSgSKLDFJSKLDFJ\" -> False
# ```

# ```
# \"ACSKLDFJSGSKLDFJSKLDFJ\" -> True
# ```

# **Remarque** : Dans ce Kata, une chaîne est dite en MAJUSCULES lorsqu'elle ne contient aucune lettre minuscule, donc toute chaîne ne contenant aucune lettre est trivialement considérée comme étant en MAJUSCULES.
# "
# )


# e = Exercice.create!(
#   name: "Counting Duplicates", 
#   cw_token: "54bf1c2cd5b56cc47f0007a1", 
#   position: 1, 
#   course: Course.find_by(position: 3), 
#   kata: 6,
#   description: "## Description:

#   Écrivez une fonction qui renverra le nombre de caractères alphabétiques distincts, insensibles à la casse , et de chiffres numériques qui apparaissent plusieurs fois dans la chaîne d'entrée. On peut supposer que la chaîne d'entrée contient uniquement des lettres (majuscules et minuscules) et des chiffres numériques.

# ### Exemples : (Entrée --> Sortie)

# ```
# \"abcde\" -> 0 # no characters repeats more than once
# ```

# ```
# \"aabbcde\" -> 2 # 'a' and 'b'
# ```

# ```
# \"aabBcde\" -> 2 # 'a' occurs twice and 'b' twice (`b` and `B`)
# ```

# ```
# \"indivisibilité\" -> 1 # 'i' occurs six times
# ```

# ```
# \"Indivisibilités\" -> 2 # 'i' occurs seven times and 's' occurs twice
# ```

# ```
# \"aA11\" -> 2 # 'a' and '1'
# ```

# ```
# \"ABBA\" -> 2 # 'A' and 'B' each occur twice
# ```
# "
# )
# Exercice.create!(
#   name: "Beginner - Reduce but Grow", 
#   cw_token: "57f780909f7e8e3183000078", 
#   position: 1, 
#   course: Course.find_by(position: 2), 
#   kata: 8,
#   description: "## Description:
# Pour une liste non vide d'entiers, renvoyer le résultat de la multiplication de toutes les valeurs de la liste. 

# ### Exemples : (Entrée --> Sortie)

# ```
# [1, 2, 3, 4] --> 1 * 2 * 3 * 4 = 24
# ```
# "
# )

# Exercice.create!(
#   name: "Calculate average", 
#   cw_token: "57a2013acf1fa5bfc4000921", 
#   position: 2, 
#   course: Course.find_by(position: 2), 
#   kata: 8,
#   description: "## Description:

# Écrivez une fonction qui calcule la moyenne des nombres dans une liste donnée.

# **Remarque** : les tableaux vides doivent renvoyer 0.
# "
# )

# Exercice.create!(
#   name: "Beginner - Lost Without a Map", 
#   cw_token: "57f781872e3d8ca2a000007e", 
#   position: 3, 
#   course: Course.find_by(position: 2), 
#   kata: 8,
#   description: "## Description:

# Pour une liste d'entiers, renvoyez une nouvelle liste avec chaque valeur doublée.

# ### Exemples : (Entrée --> Sortie)

# ```
# [1, 2, 3] --> [2, 4, 6]
# ```
# "
# )

# Exercice.create!(
#   name: "Sum Arrays", 
#   cw_token: "53dc54212259ed3d4f00071c", 
#   position: 4, 
#   course: Course.find_by(position: 2), 
#   kata: 8,
#   description: "## Description:

# Écrivez une fonction qui prend une liste de nombres et renvoie la somme des nombres. 
# Les nombres peuvent être négatifs ou non entiers. 
# Si la liste ne contient aucun nombre, vous devez renvoyer 0.

# ### Exemples : (Entrée --> Sortie)

# ```
# [1, 5.2, 4, 0, -1] --> 9.2
# ```

# ```
# [] --> 0
# ```

# ```
# [-2.398] --> -2.398
# ```

# ### Hypothèses
# - Vous pouvez supposer que vous ne recevez que des nombres.
# - Vous ne pouvez pas supposer la taille de la liste.
# - Vous pouvez supposer que vous obtenez une liste et que si la liste est vide, vous renvoyez 0.

# ### Ce que nous testons
# Nous testons des boucles de base et des opérations mathématiques. Ceci est destiné aux débutants qui apprennent juste les boucles et les opérations mathématiques.
# Les utilisateurs avancés peuvent trouver cela extrêmement facile et peuvent facilement écrire cela sur une seule ligne.
# "
# )


# Exercice.create!(
#   name: "Define a card suit", 
#   cw_token: "5a360620f28b82a711000047", 
#   position: 1, 
#   course: Course.find_by(position: 3), 
#   kata: 8,
#   description: "## Description:

# Vous recevez n'importe quelle carte comme argument. Votre tâche consiste à retourner la couleur de cette carte (en minuscules).

# Notre jeu (est préchargé) :
# ```
# DECK = ['2S','3S','4S','5S','6S','7S','8S','9S','10S','JS','QS','KS','AS',
#         '2D','3D','4D','5D','6D','7D','8D','9D','10D','JD','QD','KD','AD',
#         '2H','3H','4H','5H','6H','7H','8H','9H','10H','JH','QH','KH','AH',
#         '2C','3C','4C','5C','6C','7C','8C','9C','10C','JC','QC','KC','AC']
# ```

# ### Exemples : (Entrée --> Sortie)

# ```
# '3C' --> 'clubs'
# ```

# ```
# '3D' --> 'diamonds'
# ```

# ```
# '3H' --> 'hearts'
# ```

# ```
# '3S' --> 'spades'
# ```
# "
# )

# Exercice.create!(
#   name: "Get Planet Name By ID", 
#   cw_token: "515e188a311df01cba000003", 
#   position: 2, 
#   course: Course.find_by(position: 3), 
#   kata: 8,
#   description: "## Description:

# La fonction ne renvoie pas les valeurs correctes. Pouvez-vous comprendre pourquoi ?

# ### Exemples : (Entrée --> Sortie)

# ```
# 3 --> \"Earth\"
# ```
# "
# )

# Exercice.create!(
#   name: "Switch it Up!", 
#   cw_token: "5808dcb8f0ed42ae34000031", 
#   position: 3, 
#   course: Course.find_by(position: 3), 
#   kata: 8,
#   description: "## Description:

# Lorsqu'un nombre compris entre 0 et 9 est fourni, renvoyez-le en lettres. Notez que l'entrée est garantie d'être comprise entre 0 et 9.

# ### Exemples : (Entrée --> Sortie)

# ```
# 1 --> \"Un\"
# ```
# "
# )


# cours4 = Course.create!(
#   slides_link: "https://docs.google.com/presentation/d/e/2PACX-1vRFlPOwgPY4kMg508QbOuNKBV6RiDyv6IsuARfyZ1qJtL6wHLglCjaAY6-pJEOnaxvN8cpCzJ93v8Jb/embed?start=false&loop=false&delayms=3000",
#   position: 4, 
#   ticket_activation: false, 
#   name: "Colab, Pandas, Numpy, Matplotlib"
# )

# Exercice.create!(
#   name: "Révisions des bases en colab", 
#   cw_token: nil, 
#   colab_link: "https://colab.research.google.com/drive/1hRWK2RNEHTe1yAn23D5FYD98cD_UE_H8?usp=sharing",
#   position: 1, 
#   course: Course.find_by(position: 4), 
#   kata: 8,
#   description: "## Description:

# Exercice reprenant les bases de python.

# Pour pouvoir sauvegarder votre travail, vous devez vous connecter à votre compte Google et enregistrer une copie de ce notebook dans votre Google Drive.

# Pour cela cliquer sur \"Fichier\", puis \"Enregistrer une copie dans Drive\" 
# "
# )

# Exercice.create!(
#   name: "Dictionnaires et fonctions en colab", 
#   cw_token: nil, 
#   colab_link: "https://colab.research.google.com/drive/1pYEGIGAnSsE2IEeqPeJQJpDRfTroZ8SA?usp=sharing",
#   position: 2, 
#   course: Course.find_by(position: 4), 
#   kata: 8,
#   description: "## Description:

# Exercice reprenant les dictionnaires et les fonctions en python.

# Pour pouvoir sauvegarder votre travail, vous devez vous connecter à votre compte Google et enregistrer une copie de ce notebook dans votre Google Drive.

# Pour cela cliquer sur \"Fichier\", puis \"Enregistrer une copie dans Drive\" 
# "
# )


# cours5 = Course.create!(
#   slides_link: "https://docs.google.com/presentation/d/e/2PACX-1vQNpbbpQ20b4_-3i6FazLoiskvFCR22gWNL-b3-yyUIEuxoMYaMTY_C1PzxfMW-UnlNljaBoG7scELA/embed?start=false&loop=false&delayms=3000",
#   position: 5, 
#   ticket_activation: false, 
#   name: "Pandas avancé, Plotly"
# )

# Exercice.create!(
#   name: "Analyse et Visualisation des Pourboires", 
#   cw_token: nil, 
#   colab_link: "https://colab.research.google.com/drive/1gkwrA2rhwgwQ1gWn2USNGqWKrLlyuvpU?usp=sharing",
#   position: 1, 
#   course: Course.find_by(position: 5), 
#   kata: 8,
#   description: "## Description:

# Exercice reprenant les fondamentaux de Pandas et le tracage de graphiques avec Plotly.

# Pour pouvoir sauvegarder votre travail, vous devez vous connecter à votre compte Google et enregistrer une copie de ce notebook dans votre Google Drive.

# Pour cela cliquer sur \"Fichier\", puis \"Enregistrer une copie dans Drive\" 
# "
# )


kept_users = [
  {:first_name=>"Hawaiki", :last_name=>"Tchen"},
  {:first_name=>"Killian", :last_name=>"TEMAURI"},
  {:first_name=>"Havaiki", :last_name=>"BOSSERT"},
  {:first_name=>"Heremoana", :last_name=>"Dagues"},
  {:first_name=>"Eric", :last_name=>"LAO KY SOI"},
  {:first_name=>"Aotea", :last_name=>"TEFAATAU--GONIN"},
  {:first_name=>"Oatea", :last_name=>"Tarrats"},
  {:first_name=>"Keona", :last_name=>"Duval"},
  {:first_name=>"Ariimihinoa", :last_name=>"Lai Ah Che"},
  {:first_name=>"Rahan", :last_name=>"TCHAN"},
  {:first_name=>"Teani", :last_name=>"CUZACQ--CARRASSET"},
  {:first_name=>"Kalei", :last_name=>"TETUAMANUHIRI "},
  {:first_name=>"Bryan", :last_name=>"LIVINE"},
  {:first_name=>"Marunui", :last_name=>"TERIIEROOITERAI"},
  {:first_name=>"Manutahi", :last_name=>"Maono"}
]

kept_users.each do |user|
  User.find_by(user).update!(drop: false)
end  

Referential.destroy_all

Referential.create!(
  title: "LSPI-2 2025-2026", 
  active: true,
  batch: Batch.first
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
    referential: Referential.first
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