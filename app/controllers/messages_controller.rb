class MessagesController < ApplicationController

  def create
    @team = Team.find(params[:team_id])
    authorize @team
    @message = Message.new(message_params)
    @message.user = current_user
    @message.team = @team
    if @message.save
      current_user.update(reading: false)
      @team.users.where.not(id: current_user.id).each do |user|  
        user.update(reading: false) 
      end
      redirect_to team_path(@team, messagerie: true)
    else
      @card = Card.new
      @assignment = Assignment.new
      render "teams/show"
    end
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end
end
