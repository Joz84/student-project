# Relevé des matières du semestre en cours pour l'étudiant connecté :
# volume horaire, avancement, auto-évaluation.
class MatieresController < ApplicationController
  def show
    @team = Team.find(params[:team_id])
    authorize @team, :show?
    @meeting = Meeting.new
    @semestre = Semestre.new(current_user)
    @evaluations = UeAssessment.where(user: current_user).index_by(&:ue_id)
  end
end
