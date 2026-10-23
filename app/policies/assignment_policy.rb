class AssignmentPolicy < ApplicationPolicy
  # Affecter un étudiant à une carte, et le retirer, vont par paire : un
  # enseignant pouvait poser une affectation sans pouvoir la défaire, ce qui
  # bloquait les référents dès qu'ils corrigeaient la répartition des tâches.
  def create?
    membre? || user.teacher?
  end

  def destroy?
    membre? || user.teacher?
  end

  class Scope < ApplicationPolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      scope.all
    end
  end

  private

  def membre?
    record.team&.users&.include?(user)
  end
end
