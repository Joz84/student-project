# Les demandes de soutien nomment des étudiants en difficulté : elles ne sortent
# pas du corps enseignant.
class Teacher::SoutienPolicy < ApplicationPolicy
  def show? = user.present? && user.teacher?

  class Scope < ApplicationPolicy::Scope
    def resolve = user&.teacher? ? scope.all : scope.none
  end
end
