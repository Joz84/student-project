class Teacher::MessagesController < ApplicationController
  def index
    session[:team_id] = params[:team_id].to_i if params[:team_id]
    @teams = policy_scope([:teacher, Team])
    if session[:team_id] != 0 
      @teams = @teams.where(id: session[:team_id])
    end
    current_user.update(reading: true)
  end

  def create
    @message = Message.new(message_params)
    @message.user = current_user
    authorize [:teacher, @message]
    if @message.save
      current_user.update(reading: false)
      @message.team.users.each do |user|  
        user.update(reading: false) 
      end
      @message.team.project.teachers.where.not(id: current_user.id).each do |user|  
        user.update(reading: false) 
      end
      redirect_to teacher_messages_path(team_id: @message.team.id)
    else
      flash[:alert] = "Le message n'a pas pu être envoyé"
      redirect_to teacher_messages_path
    end
  end

  private

  def message_params
    params.require(:message).permit(:content, :team_id)
  end

end