class AttemptPolicy < ApplicationPolicy
  def create?
    (record.user == user) || user.teacher?
  end

  class Scope < ApplicationPolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      scope.all
    end
  end
end