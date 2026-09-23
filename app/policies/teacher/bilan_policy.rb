class Teacher::BilanPolicy < ApplicationPolicy
  def show?   = user&.teacher?
  def update? = show?
  def export? = show?
  def import? = show?

  class Scope < ApplicationPolicy::Scope
    def resolve = user&.teacher? ? scope.all : scope.none
  end
end
