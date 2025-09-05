class MeetingsController < ApplicationController
  def create
    @team = Team.find(params[:team_id])
    @meeting = Meeting.new(meeting_params)
    @meeting.team = @team
    @meeting.referential = @team.project.batch.current_referential
    authorize @meeting
    if @meeting.save
      redirect_to @team
    else
      @card = Card.new
      @assignment = Assignment.new
      @all_skills = @team.project.batch.current_referential.skills
      render "teams/show", status: :unprocessable_entity
    end
  end
  
  def update
    @team = Team.find(params[:team_id])
    @meeting = Meeting.find(params[:id])
    authorize @meeting
    if @meeting.update(meeting_params)
      redirect_to @team
    else
      @card = Card.new
      @assignment = Assignment.new
      @all_skills = @team.project.batch.current_referential.skills
      render "teams/show", status: :unprocessable_entity
    end
  end

  def destroy
    @team = Team.find(params[:team_id])
    @meeting = Meeting.find(params[:id])
    authorize @meeting
    @meeting.destroy
    redirect_to @team
  end

  private

  def meeting_params
    params.require(:meeting).permit(
      :date, 
      :place, 
      :note, 
      :progress,
      presences_attributes: [:id, :progress])
  end

end
