class AttemptsController < ApplicationController
  def create
    @exercice = Exercice.find(params[:exercice_id])
    @attempt = @exercice.attempts.new(user: current_user) 
    @attempt.succeeded = true
    authorize @attempt
    @attempt.save
    redirect_to course_exercices_path(@exercice.course)
  end
end
