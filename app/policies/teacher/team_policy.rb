class Teacher::TeamPolicy < ApplicationPolicy
  def index?
    user.teacher? 
  end

  def show?
    user.teacher?
  end

  def update?
    user.teacher?
  end

  class Scope < ApplicationPolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      scope.all
    end
  end
end

