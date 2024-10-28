class AssignmentsController < ApplicationController

  def destroy
    @assignment = Assignment.find(params[:id])
    authorize @assignment
    @team = @assignment.team
    @assignment.destroy
    redirect_to @team
  end

  def create
    @assignment = Assignment.new(assignment_params)
    @card = Card.find(params[:card_id])
    @assignment.card = @card
    authorize @assignment
    @assignment.save
    redirect_to @assignment.team
  end

  private

  def assignment_params
    params.require(:assignment).permit(:user, :user_id)
  end
end
