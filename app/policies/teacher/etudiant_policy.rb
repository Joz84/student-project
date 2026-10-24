# La fiche d'un étudiant réunit tout ce que la plateforme sait de lui :
# assiduité, auto-évaluations, demandes de soutien, projet. C'est de quoi
# préparer un entretien, et c'est le travail de tout enseignant — elle ne sort
# pas pour autant du corps enseignant.
class Teacher::EtudiantPolicy < ApplicationPolicy
  def show? = user.present? && user.teacher?

  # La liste d'ensemble donne accès aux fiches en un clic : même porte.
  def index? = show?

  # L'écran de l'étudiant, lui, reste à l'administration. Se mettre à sa place
  # n'est pas lire son dossier : c'est voir l'interface où il déclare son
  # niveau et demande du soutien, et cela sert à accompagner le dispositif,
  # pas à enseigner.
  def matieres? = user.present? && user.admin?

  class Scope < ApplicationPolicy::Scope
    def resolve = user&.teacher? ? scope.all : scope.none
  end
end
