class MessagesController < ApplicationController

  def index
    @messages = policy_scope(Message)
    @team = Team.find(params[:team_id])
    @message = Message.new
    current_user.update(reading: true)
  end

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
      current_user.team.project.teachers.each do |user|  
        user.update(reading: false) 
      end

      redirect_to team_messages_path(@team)
    else
      @messages = policy_scope(Message)
      render "teams/show"
    end
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end
end
