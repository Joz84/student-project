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
    load_equipes_par_enseignant
    @project_demand = @batch.project_demand
    load_avancement
    load_repartition
  end

  # Où en est chaque élève dans le classement de ses vœux.
  def load_avancement
    eleves = @batch.users.kept.where(teacher: nil)
                   .includes(:ratings, :speciality)
                   .order(:last_name, :first_name)
    @valides, en_cours = eleves.partition(&:booked?)
    @modifies, @non_modifies = en_cours.partition(&:ratings_reordered?)
  end

  # Les équipes de chaque enseignant, en une passe plutôt qu'une requête par projet.
  def load_equipes_par_enseignant
    # Une équipe sans projet ne peut être rattachée à aucun référent — d'anciennes
    # promos en comptent, créées avant qu'un projet leur soit attribué.
    toutes = @teams.includes(:project, :users).to_a
    equipes, @equipes_sans_projet = toutes.partition(&:project)
    supervisions = Supervision.where(project_id: equipes.map(&:project_id).uniq)
                              .pluck(:project_id, :user_id)
                              .each_with_object(Hash.new { |h, k| h[k] = [] }) { |(p, u), h| h[p] << u }
    @equipes_par_enseignant = Hash.new { |h, k| h[k] = [] }
    equipes.sort_by { |t| [t.project.name.to_s, t.name.to_s] }.each do |t|
      supervisions[t.project_id].each { |uid| @equipes_par_enseignant[uid] << t }
    end
  end

  # Matrice « qui a eu quel vœu », pour expliquer aux élèves le choix de l'algorithme.
  # Le rang du vœu est l'unité lisible : « tu as eu ton 2e vœu ».
  def load_repartition
    teams = @teams.includes(:project, users: :ratings).select(&:project)
    return if teams.empty?

    @repartition_projects = @batch.projects.order(:id).to_a
    @repartition_rows = []
    teams.sort_by { |t| [t.project.name, t.name] }.each do |team|
      membres = team.users.reject { |u| u[:drop] }
                    .sort_by { |u| [u.last_name.to_s.downcase, u.first_name.to_s.downcase] }
      membres.each_with_index do |user, i|
        ranks = user.ratings.each_with_object({}) { |r, h| h[r.project_id] = r.position }
        @repartition_rows << { team: team, first: i.zero?, size: membres.size, user: user,
                               ranks: ranks, total: ranks.size, granted: ranks[team.project_id] }
      end
    end

    obtenus = @repartition_rows.filter_map { |r| r[:granted] }
    @satisfaction = obtenus.tally.sort.to_h
    @average_rank = obtenus.any? ? (obtenus.sum.to_f / obtenus.size).round(2) : nil
    @top_share = obtenus.any? ? (100.0 * obtenus.count { |r| r <= 3 } / obtenus.size).round : nil
  end

  def team_params
    params.require(:team).permit(:project_id)
  end
end
