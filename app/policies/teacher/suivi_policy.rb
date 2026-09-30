class Teacher::SuiviPolicy < ApplicationPolicy
  def show? = user.present? && user.admin?

  class Scope < ApplicationPolicy::Scope
    def resolve = user&.admin? ? scope.all : scope.none
  end
end
