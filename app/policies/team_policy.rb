class TeamPolicy < ApplicationPolicy
  def new
    true
  end

  def create?
    true
    #record.user == user
  end

  def update?
    #record.user == user
    true
  end

  def show?
    true
  end

  class Scope < ApplicationPolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      scope.all
    end
  end
end
