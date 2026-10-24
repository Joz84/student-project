class UeAssessmentPolicy < ApplicationPolicy
  # Chacun évalue son propre niveau, personne d'autre — et un enseignant n'a
  # pas de niveau à déclarer. Le contrôleur construit toujours la ligne pour
  # le compte connecté : la règle ne protège donc pas l'étudiant d'un
  # enseignant, elle empêche l'enseignant de se créer un relevé qui n'a pas
  # de sens, en pressant les boutons d'un écran qui n'est pas le sien.
  def update?
    return false if user.nil? || user.teacher?
    record.user_id == user.id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.where(user: user)
  end
end
