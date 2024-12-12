class ExamNicknamesController < ApplicationController

  def create
    authorize current_user
    current_user.exam_nickname = user_params["exam_nickname"]
    if current_user.exam_nickname_is_valid? && current_user.save
        redirect_to default_course
    else
      flash[:alert] = "Pseudo codewars est incorrect"
      redirect_to default_course
    end
  end

  private

  def user_params
    params.require(:user).permit(:exam_nickname)
  end

end
