class CwNicknamesController < ApplicationController
  def router
    authorize current_user
    if current_user.cw_nickname.present?
      redirect_to default_course
    else
      redirect_to edit_cw_nickname_path(current_user)
    end
  end

  def edit
    authorize current_user
  end

  def update
    authorize current_user
    current_user.cw_nickname = user_params["cw_nickname"]
    if current_user.cw_nickname_is_valid? && current_user.save
        redirect_to default_course
    else
      flash[:alert] = "Nickname codewars est incorrect"
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:cw_nickname)
  end
end
