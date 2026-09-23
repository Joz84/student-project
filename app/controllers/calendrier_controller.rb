# Emploi du temps hebdomadaire de l'étudiant connecté.
class CalendrierController < ApplicationController
  def show
    # L'autorisation passe avant le masquage : une sortie anticipée qui ne
    # l'appelle pas est justement ce que Pundit refuse.
    authorize current_user, :show?
    return redirect_to root_path unless Calendrier.actif?

    @calendrier = Calendrier.new(current_user, date: semaine_demandee)
  end

  private

  # Une date illisible dans l'adresse ne doit ni casser la page ni court-circuiter
  # l'autorisation : on retombe simplement sur la semaine courante.
  def semaine_demandee
    return Date.current if params[:semaine].blank?
    Date.parse(params[:semaine])
  rescue Date::Error
    Date.current
  end
end
