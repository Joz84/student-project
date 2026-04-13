class UserSkillStatusesController < ApplicationController
  def update
    @status = UserSkillStatus.find_or_initialize_by(
      user_id: params[:user_id],
      skill_id: params[:skill_id]
    )
    authorize @status
    @status.status = params[:status]
    @status.save!
    render json: { status: @status.status }, status: :ok
  end
end
