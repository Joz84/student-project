class ProjectPolicy < ApplicationPolicy
  def router?
    true
  end

  def show?
    user.teacher? || user.eligible_projects.exists?(record.id)
  end

  class Scope < ApplicationPolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      scope.where(id: user.eligible_projects)
    end
  end
end
