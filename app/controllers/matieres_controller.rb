# Relevé personnel des matières du semestre en cours : volume horaire,
# avancement, travail personnel et auto-évaluation. Page propre à l'étudiant
# connecté, atteignable depuis l'accueil.
class MatieresController < ApplicationController
  def show
    @semestre = Semestre.new(current_user)
    @evaluations = UeAssessment.where(user: current_user).index_by(&:ue_id)
    @statut = @semestre.statut(@evaluations)
    @demandes = TutoringRequest.where(user: current_user).pluck(:ue_id).to_set

    # Son assiduité. Un enseignant peut le porter absent des jours après le
    # cours : sans cette page, il ne l'apprendrait jamais.
    @assiduite = Assiduite.par_matiere(current_user).index_by { |m| m[:ue].id }
    @pointages = Attendance.where(user: current_user).includes(lesson: :ue)
                           .joins(:lesson).order("lessons.starts_at DESC").limit(30)
    authorize current_user, :show?
  end
end
