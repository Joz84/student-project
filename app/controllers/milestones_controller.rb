class MilestonesController < ApplicationController
  before_action :charger_equipe
  before_action :charger_jalon, except: [:create]

  def create
    @milestone = @team.milestones.new(milestone_params)
    authorize @milestone
    if @milestone.save
      redirect_to team_roadmap_path(@team), notice: "Jalon « #{@milestone.name} » créé.", status: :see_other
    else
      redirect_to team_roadmap_path(@team), alert: erreurs(@milestone), status: :see_other
    end
  end

  def update
    if @milestone.update(milestone_params)
      redirect_to team_roadmap_path(@team), notice: "Jalon mis à jour.", status: :see_other
    else
      redirect_to team_roadmap_path(@team), alert: erreurs(@milestone), status: :see_other
    end
  end

  def destroy
    nom = @milestone.name
    # Les tâches ne sont pas supprimées avec le jalon : elles se retrouvent
    # simplement sans rattachement.
    @milestone.destroy!
    redirect_to team_roadmap_path(@team),
                notice: "Jalon « #{nom} » supprimé. Ses tâches restent au tableau.", status: :see_other
  end

  def monter
    @milestone.move_higher
    redirect_to team_roadmap_path(@team), status: :see_other
  end

  def descendre
    @milestone.move_lower
    redirect_to team_roadmap_path(@team), status: :see_other
  end

  private

  def charger_equipe
    @team = Team.find(params[:team_id])
  end

  def charger_jalon
    @milestone = @team.milestones.find(params[:id])
    authorize @milestone
  end

  def milestone_params
    params.require(:milestone).permit(:name, :description, :starts_on, :due_on, :color)
  end

  def erreurs(m)
    m.errors.full_messages.join(". ")
  end
end
