class TeamPolicy < ApplicationPolicy
  def create?
    true
  end

  def update?
    user.team == record || user.teacher?
  end

  def show?
    user.team == record || user.teacher?
  end

  class Scope < ApplicationPolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      scope.all
    end
  end
end
