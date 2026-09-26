# L'étudiant demande ou retire du soutien sur une UE. Une seule action qui
# bascule : le bouton porte l'état courant, pas une opération à choisir.
class TutoringRequestsController < ApplicationController
  def create
    @ue = Ue.find(params[:ue_id])
    demande = TutoringRequest.find_or_initialize_by(user: current_user, ue: @ue)
    authorize demande

    if demande.persisted?
      demande.destroy!
      message = "Demande de soutien retirée pour #{@ue.name}."
    else
      demande.save!
      message = "Demande de soutien enregistrée pour #{@ue.name}."
    end

    redirect_back fallback_location: matieres_path, notice: message, status: :see_other
  end
end
