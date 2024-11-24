class Teacher::MessagePolicy < ApplicationPolicy
  def index?
    user.teacher? 
  end

  def create?
    record.user == user && user.supervised_teams.include?(record.team)
  end

  class Scope < ApplicationPolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      scope.where(team: user.supervised_teams)
    end
  end
end

