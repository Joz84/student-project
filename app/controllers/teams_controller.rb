class TeamsController < ApplicationController
  def new
    @team = Team.new
    authorize @team
  end

  def create
    @team = Team.new(team_params)
    authorize @team
    if @team.save
      current_user.team.destroy if current_user.team&.users&.count == 1
      current_user.update(team: @team)
      redirect_to projects_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @team = Team.find(params[:id])
    authorize @team
    @card = Card.new
    @assignment = Assignment.new
    @message = Message.new
    current_user.update(reading: true)
  end

  private

  def team_params
    params.require(:team).permit(:name)
  end
end
