class CardSkillPolicy < ApplicationPolicy
  def destroy?
    record.card.list.team&.users&.include?(user) || user.teacher?
  end

  def create?
    record.card.list.team&.users&.include?(user) || user.teacher?
  end

  class Scope < ApplicationPolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      scope.all
    end
  end
end
