class Teacher::AttendancePolicy < ApplicationPolicy
  def update?  = user.teacher?
  def create?  = user.teacher?
  def destroy? = user.teacher?

  class Scope < ApplicationPolicy::Scope
    def resolve = user.teacher? ? scope.all : scope.none
  end
end
