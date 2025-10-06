class Teacher::TeamsController < ApplicationController
  def index
    @batches = current_user.supervised_batches
    @teams = policy_scope([:teacher, Team])
    @batch_id = params[:batch_id] || session[:batch_id] || @batches.last.id
    if @batch_id
      @batch = Batch.find(@batch_id)
      session[:batch_id] = @batch_id
      @teams = @teams
        .joins(:users)
        .where(users: { batch_id: @batch_id })
        .distinct
        .kept
      @teachers = @batch.teachers.joins(supervisions: { project: :teams }).distinct
      @teachers = @teachers.where(id: current_user.id) if !current_user.admin
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
