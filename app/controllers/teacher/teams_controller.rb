class Teacher::TeamsController < ApplicationController
  def index
    @teams = policy_scope([:teacher, Team])
  end

  def show
    @team = Team.find(params[:id])
    authorize [:teacher, @team]
  end
end
