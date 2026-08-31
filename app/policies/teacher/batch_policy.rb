class Teacher::BatchPolicy < ApplicationPolicy
  def solver_payload?
    user.teacher? && (user.admin? || user.supervised_batches.exists?(record.id))
  end

  def import?
    solver_payload?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(id: user.supervised_batches)
    end
  end
end
