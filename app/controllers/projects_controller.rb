class ProjectsController < ApplicationController
  def index
    @projects = policy_scope(Project)
  end

  def show
  end

  def router
    authorize Project.new
    if current_user.teacher
      redirect_to teacher_teams_path
    elsif current_user.team_id.nil?
      redirect_to new_team_path
    elsif current_user.team.project.nil?
      redirect_to projects_path
    else
      redirect_to current_user.team
    end
  end
end
