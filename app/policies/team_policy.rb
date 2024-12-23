class TeamPolicy < ApplicationPolicy
  def create?
    true
  end

  def update?
    (record == user.team) || user.teacher?
  end

  def show?
    (record == user.team) || user.teacher?
  end

  class Scope < ApplicationPolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      scope.all
    end
  end
end
