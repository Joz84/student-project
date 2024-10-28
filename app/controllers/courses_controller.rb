class CoursesController < ApplicationController
  def show
    session[:course_id] = params[:id]
    @course = Course.find(params[:id])
    authorize @course
    @markdown_content = MarkdownFetcher.new(@course).run
    render layout: "courses_sidebar_layout"
  end
end
