class Teacher::AttendancePolicy < ApplicationPolicy
  def update? = user.teacher?

  class Scope < ApplicationPolicy::Scope
    def resolve = user.teacher? ? scope.all : scope.none
  end
end
