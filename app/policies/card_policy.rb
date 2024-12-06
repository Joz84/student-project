class CardPolicy < ApplicationPolicy
  def destroy?
    record.team&.users&.include?(user) || user.teacher?
  end

  def create?
    record.team&.users&.include?(user) || user.teacher?
  end

  def update?
    record.team&.users&.include?(user) || user.teacher?
  end    

  def position?
    record.team&.users&.include?(user) || user.teacher?
  end

  class Scope < ApplicationPolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      scope.all
    end
  end
end
