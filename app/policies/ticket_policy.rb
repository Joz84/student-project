class TicketPolicy < ApplicationPolicy
  def create?
    record.user == user
  end

  def update?
    user.teacher
  end

  def destroy?
    record.user == user && record.pending?
  end

  class Scope < ApplicationPolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      scope.all
    end
  end
end
