class MeetingPolicy < ApplicationPolicy
  def create?
    (record.team == user.team) || user.teacher?
  end

  def update?
    (record.team == user.team) || user.teacher?
  end

  def destroy?
    (record.team == user.team) || user.teacher?
  end
  
  class Scope < ApplicationPolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      scope.all
    end
  end
end
