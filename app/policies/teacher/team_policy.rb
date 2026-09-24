class Teacher::TeamPolicy < ApplicationPolicy
  def index?
    user.teacher? 
  end

  def show?
    user.teacher?
  end

  def update?
    user.teacher?
  end

  class Scope < ApplicationPolicy::Scope
    # Un étudiant n'a rien à lire ici. Les enseignants voient toutes les
    # équipes : la page les regroupe ensuite par référent.
    def resolve
      user&.teacher? ? scope.all : scope.none
    end
  end
end

