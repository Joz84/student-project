# Pas de ligne `web:` : le buildpack Ruby fournit la sienne, et la redéclarer
# risquerait de changer la façon dont le dyno démarre.
#
# La phase de release joue les migrations avant que le nouveau code reçoive du
# trafic. Sans elle, un déploiement qui ajoute une table laisse une fenêtre où
# les pages qui l'interrogent renvoient une erreur.
release: bundle exec rails db:migrate
