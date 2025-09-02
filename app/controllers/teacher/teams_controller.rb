class Teacher::TeamsController < ApplicationController
  def index
    @teams = policy_scope([:teacher, Team])
    @batch_id = params[:batch_id] || session[:batch_id] || @batchs.last.id
    if @batch_id
      @batchs = current_user.supervised_batches
      @batch = Batch.find(@batch_id)
      session[:batch_id] = @batch_id
      @teams = @teams
        .joins(:project)
        .where(projects: { batch_id: @batch_id })
        .distinct
        .kept
    end
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
