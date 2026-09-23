class RoadmapsController < ApplicationController
  def show
    @team = Team.find(params[:team_id])
    authorize @team, :show?
    @milestones = @team.milestones.ordonnes.includes(cards: :list)
    @orphelines = @team.cards.where(milestone_id: nil).where.not(status: :hidden).includes(:list)
    @milestone = Milestone.new
  end
end
