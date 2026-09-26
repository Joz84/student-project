class TutoringRequestPolicy < ApplicationPolicy
  # Chacun demande du soutien pour lui-même, et seulement sur une UE qu'il suit.
  def create?
    return false if user.nil? || user.teacher?
    record.user_id == user.id && user.group_ids.intersect?(record.ue.group_ids)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.where(user: user)
  end
end
