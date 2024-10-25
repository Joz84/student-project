class ProjectsController < ApplicationController
  def index
    @projects = policy_scope(Project)
  end

  def show
  end

  def router
    authorize Project.new
    if current_user.team_id.nil?
      redirect_to new_team_path
    elsif current_user.pending?
      redirect_to projects_path
    elsif current_user.team.pending?
      redirect_to projects_path
    else
      redirect_to current_user.project
    end
  end
end
