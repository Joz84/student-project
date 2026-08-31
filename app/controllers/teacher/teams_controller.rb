class Teacher::TeamsController < ApplicationController
  def index
    load_index
  end

  # Exporte l'entrée du solveur : à déposer dans repartition_algorithme/
  def solver_payload
    @batch = Batch.find(params[:batch_id])
    authorize [:teacher, @batch], :solver_payload?
    send_data JSON.pretty_generate(@batch.solver_payload),
              filename: "payload-#{@batch.title.parameterize}.json",
              type: "application/json"
  end

  # Reçoit la sortie du solveur et crée les équipes.
  # Le bouton « Simuler » vérifie sans rien écrire, « Importer » crée.
  def import
    @batch = Batch.find(params[:batch_id])
    authorize [:teacher, @batch], :import?
    if params[:assignment].blank?
      flash.now[:alert] = "Aucun fichier sélectionné."
    else
      @import = TeamsImporter.new(@batch, params[:assignment].read)
                             .run(dry_run: params[:commit] != "Importer")
    end
    render_index
  rescue JSON::ParserError
    flash.now[:alert] = "Fichier illisible : ce n'est pas du JSON valide."
    render_index
  end

  def show
    @team = Team.find(params[:id])
    authorize [:teacher, @team]
  end

  def update
    @team = Team.find(params[:id])
    authorize [:teacher, @team]
    @team.update(team_params)
    redirect_to teacher_teams_path
  end

  private

  def render_index
    load_index(params[:batch_id])
    render :index, status: @import&.ok? == false ? :unprocessable_entity : :ok
  end

  def load_index(forced_batch_id = nil)
    @batches = current_user.supervised_batches
    @teams = policy_scope([:teacher, Team])
    @batch_id = forced_batch_id || params[:batch_id] || session[:batch_id] || @batches.last&.id
    return if @batch_id.nil?

    @batch = Batch.find(@batch_id)
    session[:batch_id] = @batch_id
    @teams = @teams
      .joins(:users)
      .where(users: { batch_id: @batch_id })
      .where.not(name: "En attente de projet")
      .distinct
      .kept
    @teachers = @batch.teachers.joins(supervisions: { project: :teams }).distinct
    @teachers = @teachers.where(id: current_user.id) if !current_user.admin
  end

  def team_params
    params.require(:team).permit(:project_id)
  end
end
