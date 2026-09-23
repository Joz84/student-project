class MilestonePolicy < ApplicationPolicy
  # La feuille de route appartient à l'équipe : ses membres la tiennent,
  # les enseignants peuvent la consulter et la corriger.
  def create?  = membre? || user.teacher?
  def update?  = create?
  def destroy? = create?
  def monter?  = create?
  def descendre? = create?

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.where(team_id: user.team_id)
  end

  private

  def membre? = user.team_id.present? && user.team_id == record.team_id
end
