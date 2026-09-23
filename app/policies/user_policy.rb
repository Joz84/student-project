class UserPolicy < ApplicationPolicy
  def router?
    true
  end

  def create?
    true
  end
  
  def update?
    record == user
  end

  # Le relevé de matières est personnel : on ne consulte que le sien.
  def show?
    record == user
  end

  class Scope < ApplicationPolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      scope.all
    end
  end
end
