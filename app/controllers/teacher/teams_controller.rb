class Teacher::TeamsController < ApplicationController
  def index
    @teams = policy_scope([:teacher, Team]).kept
  end

  def show
    @team = Team.find(params[:id])
    authorize [:teacher, @team]
  end

  def update
    @team = Team.find(params[:id])
    authorize [:teacher, @team]
    @team.update(team_params)
    redirect_to teacher_teams_path
  end

  private

  def team_params
    params.require(:team).permit(:project_id)
  end
end
