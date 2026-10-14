class TeamPolicy < ApplicationPolicy
  def create?
    true
    #record.user == user
  end

  def update?
    (record == user.team) || user.teacher?
  end

  # Un étudiant relit le tableau d'une équipe qu'il a quittée : son travail de
  # l'année passée ne disparaît pas parce qu'il a changé de projet. Modifier
  # reste réservé à l'équipe du moment, par `update?`.
  def show?
    user.teacher? || user.a_frequente?(record)
  end

  class Scope < ApplicationPolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      scope.all
    end
  end
end
