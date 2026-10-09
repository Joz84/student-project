class Teacher::LessonPolicy < ApplicationPolicy
  def show?          = user.teacher?
  def new?           = user.teacher?
  def create?        = new?
  def destroy?       = user.teacher?
  def liste?         = show?
  def ouvrir?        = show?
  def verrouiller?   = show?
  def deverrouiller? = show?
  def rouvrir?       = show?
  def valider?       = show?
  def oublier?       = show?
  def tous_presents? = show?
  def update?        = show?

  class Scope < ApplicationPolicy::Scope
    def resolve = user.teacher? ? scope.all : scope.none
  end
end
