# Emploi du temps hebdomadaire de l'étudiant connecté.
class CalendrierController < ApplicationController
  def show
    @calendrier = Calendrier.new(current_user, date: semaine_demandee)
    authorize current_user, :show?
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
