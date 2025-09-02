class ProjectPolicy < ApplicationPolicy
  def router?
    true
  end

  class Scope < ApplicationPolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      scope.where(batch: user.batch)
    end
  end
end
