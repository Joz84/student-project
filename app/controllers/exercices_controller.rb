class ExercicesController < ApplicationController
  def index
    @course = Course.find(params[:course_id])
    @exercices = policy_scope(Exercice).where(course_id: params[:course_id])
    current_user.update_attempts
    render layout: "courses_sidebar_layout"
  end
end
