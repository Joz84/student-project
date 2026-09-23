class UeAssessmentPolicy < ApplicationPolicy
  # Chacun évalue son propre niveau, personne d'autre.
  def update? = user.present? && record.user_id == user.id

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.where(user: user)
  end
end
