class RoadmapsController < ApplicationController
  def show
    @team = Team.find(params[:team_id])
    authorize @team, :show?
    @milestones = @team.milestones.ordonnes.includes(cards: :list)
    @gantt = RoadmapGantt.new(@milestones)
    @orphelines = @team.cards.where(milestone_id: nil).where.not(status: :hidden).includes(:list)
    @meeting = Meeting.new   # la barre latérale propose d'en créer un
    @milestone = Milestone.new
  end
end
