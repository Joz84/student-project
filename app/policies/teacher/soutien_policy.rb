# Les demandes de soutien nomment des étudiants en difficulté, et leur
# avancement déclaré est plus personnel encore : la page ne sort pas de
# l'administration.
class Teacher::SoutienPolicy < ApplicationPolicy
  def show?       = user.present? && user.admin?
  def avancement? = show?

  class Scope < ApplicationPolicy::Scope
    def resolve = user&.admin? ? scope.all : scope.none
  end
end
