class SpecialitiesController < ApplicationController
  before_action :set_specialities

  def edit
    @user = current_user
    authorize @user
  end

  def update
    @user = current_user
    authorize @user
    speciality = @specialities.find_by(id: params.dig(:user, :speciality_id))
    if speciality && @user.update(speciality: speciality)
      redirect_to project_router_path
    else
      flash.now[:alert] = "Merci de sélectionner une spécialité."
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_specialities
    @specialities = current_user.batch.specialities
  end
end
