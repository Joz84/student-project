# Relevé personnel des matières du semestre en cours : volume horaire,
# avancement, travail personnel et auto-évaluation. Page propre à l'étudiant
# connecté, atteignable depuis l'accueil.
class MatieresController < ApplicationController
  def show
    @semestre = Semestre.new(current_user)
    @evaluations = UeAssessment.where(user: current_user).index_by(&:ue_id)
    @statut = @semestre.statut(@evaluations)
    authorize current_user, :show?
  end
end
