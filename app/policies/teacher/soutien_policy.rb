# Les demandes de soutien nomment des étudiants en difficulté : elles ne sortent
# pas du corps enseignant.
class Teacher::SoutienPolicy < ApplicationPolicy
  def show? = user.present? && user.teacher?

  # Le récapitulatif sert à arbitrer l'ouverture des séances : il ne sort pas
  # de l'administration.
  def recap? = user.present? && user.admin?

  class Scope < ApplicationPolicy::Scope
    def resolve = user&.teacher? ? scope.all : scope.none
  end
end
