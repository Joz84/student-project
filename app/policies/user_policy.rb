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

  class Scope < ApplicationPolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      scope.all
    end
  end
end
