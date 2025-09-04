class ProgressionsController < ApplicationController
  def index
    @team = Team.find(params[:team_id])
    authorize @team, :show?
    @users = policy_scope(User).where(team: @team).kept
    @referential = @team.project.batch.referentials.find_by(active: true)
    @skill_blocks = @referential.skill_blocks.includes(:skills).order(:position)
  end
end
