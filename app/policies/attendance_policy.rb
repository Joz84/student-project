class AttendancePolicy < ApplicationPolicy
  def create?
    record.lesson.concerne?(user)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.where(user: user)
  end
end
