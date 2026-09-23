class UeAssessmentsController < ApplicationController
  def update
    @ue = Ue.find(params[:ue_id])
    evaluation = UeAssessment.find_or_initialize_by(user: current_user, ue: @ue)
    authorize evaluation

    if params[:level].blank?
      # Revenir à « non évalué » est un choix légitime.
      evaluation.destroy if evaluation.persisted?
    else
      evaluation.update!(level: params[:level])
    end
    redirect_back fallback_location: root_path
  end
end
