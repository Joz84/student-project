class UeAssessmentsController < ApplicationController
  def update
    @ue = Ue.find(params[:ue_id])
    evaluation = UeAssessment.find_or_initialize_by(user: current_user, ue: @ue)
    authorize evaluation

    evaluation.level = params[:level].presence if params.key?(:level)
    evaluation.home_hours = params[:home_hours].to_f if params.key?(:home_hours)

    # Une ligne sans niveau ni heures n'a plus de raison d'exister.
    if evaluation.vide?
      evaluation.destroy if evaluation.persisted?
    else
      evaluation.save!
    end
    redirect_back fallback_location: matieres_path, status: :see_other
  end
end
