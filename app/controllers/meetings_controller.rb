class MeetingsController < ApplicationController
  def update
    @team = Team.find(params[:team_id])
    authorize @team
    if @team.update(meeting_params)
      redirect_to @team
    else
      @card = Card.new
      @assignment = Assignment.new
      render "teams/show", status: :unprocessable_entity
    end
  end

  private

  def meeting_params
    params.require(:team).permit(:meeting_date, :meeting_place)
  end

end
