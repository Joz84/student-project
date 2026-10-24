# La fiche d'un étudiant : tout ce que la plateforme sait de lui, réuni sur
# une page. Sert à préparer un entretien, ou à comprendre une situation avant
# de la commenter.
class Teacher::EtudiantsController < ApplicationController
  # La vue d'ensemble de la promotion, regroupée au choix par projet, par TD ou
  # par TP. `authorize` en plus de la portée : sans lui, un étudiant connecté
  # atteignait la page en passant ?batch_id= dans l'adresse.
  def index
    authorize [:teacher, :etudiant], :index?
    policy_scope(User.where(teacher: nil), policy_scope_class: Teacher::EtudiantPolicy::Scope)
    @batches = Batch.where(id: User.kept.where(teacher: nil).select(:batch_id))
                    .order(:title).to_a
    @batch = params[:batch_id].present? ? Batch.find(params[:batch_id]) : promo_courante
    return if @batch.nil?

    @effectifs = Effectifs.new(@batch)
    @axe = Effectifs.axe(params[:axe]) || @effectifs.axe_par_defaut
    @paquets = @effectifs.paquets(@axe)
  end

  def show
    charger_eleve
    authorize [:teacher, :etudiant], :show?

    @ues = Ue.where(id: @eleve.groups.select(:ue_id)).order(:position, :name).to_a
    @evaluations = UeAssessment.where(user: @eleve).index_by(&:ue_id)
    @soutien = TutoringRequest.where(user: @eleve).includes(:ue).map(&:ue)
    @matieres = Assiduite.par_matiere(@eleve)
    @voeux = @eleve.ratings.includes(:project).sort_by { |r| r.position.to_i }
    @cartes = @eleve.cards.includes(:list, card_skills: :skill).to_a
    @derniers_pointages = Attendance.where(user: @eleve).includes(lesson: :ue)
                                    .joins(:lesson).order("lessons.starts_at DESC").limit(12)
  end

  # Le relevé de matières tel que l'étudiant le voit, soutien compris. La fiche
  # dit ce que l'étudiant a déclaré ; celle-ci montre l'écran où il le déclare,
  # ce qui est la seule façon de comprendre au téléphone ce qu'il a sous les
  # yeux. En lecture seule : les formulaires enregistreraient au nom de
  # l'administrateur, pas au sien.
  def matieres
    charger_eleve
    authorize [:teacher, :etudiant], :matieres?

    @apercu = true
    @semestre = Semestre.new(@eleve)
    @evaluations = UeAssessment.where(user: @eleve).index_by(&:ue_id)
    @statut = @semestre.statut(@evaluations)
    @demandes = TutoringRequest.where(user: @eleve).pluck(:ue_id).to_set
    render template: "matieres/show"
  end

  private

  def charger_eleve
    @eleve = User.where(teacher: nil).find(params[:id])
  end

  # Celle où l'on enseigne en ce moment, repérée à sa dernière séance passée :
  # le titre ne dit pas quelle promotion est en cours, et le classer par ordre
  # alphabétique ne le dirait que par chance. À défaut de séance, la dernière
  # de la liste.
  def promo_courante
    Lesson.where(batch: @batches).where("starts_at <= ?", Time.current)
          .order(starts_at: :desc).first&.batch || @batches.last
  end
end
