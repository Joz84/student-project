class Teacher::TeamsController < ApplicationController
  # `verify_authorized` dispense les index : sans cette ligne, la seule barrière
  # serait la portée de la policy, et un étudiant connecté atteignait la page
  # en passant ?batch_id= dans l'adresse.
  def index
    authorize [:teacher, Team], :index?
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
    # L'administrateur voit toutes les promotions. Le sélecteur ne listait que
    # celles qu'on encadre, et une promotion neuve — dont les projets n'ont pas
    # encore d'encadrant — n'apparaissait donc nulle part.
    @batches = current_user.admin ? Batch.order(:id) : current_user.supervised_batches
    @teams = policy_scope([:teacher, Team])
    @batch_id = forced_batch_id || params[:batch_id] || session[:batch_id] || @batches.last&.id
    return if @batch_id.nil?

    @batch = Batch.find(@batch_id)
    session[:batch_id] = @batch_id
    # Une promotion montre les équipes de ses projets, et non celles dont un
    # membre y est encore rattaché : sans cela, une promotion achevée se vide
    # de ses propres équipes dès que ses étudiants passent à la suivante.
    # Les équipes sans projet n'ont que leurs membres pour se rattacher.
    sans_projet = Team.joins(:users).where(users: { batch_id: @batch_id }, teams: { project_id: nil })
    @teams = @teams
      .where("teams.project_id IN (:projets) OR teams.id IN (:orphelines)",
             projets: @batch.projects.select(:id), orphelines: sans_projet.select(:id))
      .where.not(name: "En attente de projet")
      .distinct
    @teachers = @batch.teachers.joins(supervisions: { project: :teams }).distinct
    @teachers = @teachers.where(id: current_user.id) if !current_user.admin
    load_equipes_par_enseignant
    @project_demand = @batch.project_demand
    load_avancement
    load_repartition
  end

  # Où en est chaque étudiant dans le classement de ses vœux.
  def load_avancement
    eleves = @batch.users.kept.where(teacher: nil)
                   .includes(:ratings, :speciality, team: :project)
                   .order(:last_name, :first_name)
    @valides, en_cours = eleves.partition(&:booked?)
    @modifies, @non_modifies = en_cours.partition(&:ratings_reordered?)

    # Sans équipe au sens de l'enseignant : aucune équipe du tout, ou l'équipe
    # d'attente, qui ne donne accès à aucun tableau de bord. Les deux se
    # ressemblent de l'extérieur et doivent se lire ensemble.
    @sans_equipe = eleves.select { |u| u.team.nil? || u.team.project_id.nil? }
    @en_equipe = eleves.size - @sans_equipe.size
  end

  # Les équipes de chaque enseignant, en une passe plutôt qu'une requête par projet.
  def load_equipes_par_enseignant
    # Une équipe sans projet ne peut être rattachée à aucun référent — d'anciennes
    # promos en comptent, créées avant qu'un projet leur soit attribué.
    toutes = @teams.includes(:project, :users, :anciens_membres).to_a
    # Les équipes que plus personne ne compose — leurs membres n'ont que des
    # comptes désactivés — encombraient la grille de cartes sans un seul nom.
    # Elles se replient en bas de page plutôt que de disparaître : le travail
    # qu'elles contiennent reste atteignable.
    @equipes_vides, vivantes = toutes.partition(&:sans_membre?)
    @cartes_par_equipe = Card.joins(:list)
                             .where(lists: { team_id: @equipes_vides.map(&:id) })
                             .group("lists.team_id").count
    equipes, @equipes_sans_projet = vivantes.partition(&:project)
    supervisions = Supervision.where(project_id: equipes.map(&:project_id).uniq)
                              .pluck(:project_id, :user_id)
                              .each_with_object(Hash.new { |h, k| h[k] = [] }) { |(p, u), h| h[p] << u }
    @equipes_par_enseignant = Hash.new { |h, k| h[k] = [] }
    # Une équipe dont le projet n'a pas d'encadrant ne se rangeait sous personne
    # et disparaissait purement de la page. Elle a son propre bloc.
    @equipes_sans_encadrant = []
    equipes.sort_by { |t| [t.project.name.to_s, t.name.to_s] }.each do |t|
      referents = supervisions[t.project_id]
      @equipes_sans_encadrant << t if referents.empty?
      referents.each { |uid| @equipes_par_enseignant[uid] << t }
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
