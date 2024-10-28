class UsersController < ApplicationController
  def update
    authorize current_user
    if !user_params["team_id"].blank? && current_user.update(user_params)
      redirect_to projects_path
    else
      flash[:alert] = "Aucune team séléctionnée"
      @team = Team.new
      render "teams/new", status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:team, :team_id, :progress)
  end
end
