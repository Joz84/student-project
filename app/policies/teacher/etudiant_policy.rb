# La fiche d'un étudiant réunit tout ce que la plateforme sait de lui :
# assiduité, auto-évaluations, demandes de soutien, projet. C'est précisément
# ce qui justifie de la réserver.
class Teacher::EtudiantPolicy < ApplicationPolicy
  def show? = user.present? && user.admin?

  class Scope < ApplicationPolicy::Scope
    def resolve = user&.admin? ? scope.all : scope.none
  end
end
