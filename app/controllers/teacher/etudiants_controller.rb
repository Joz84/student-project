# La fiche d'un étudiant : tout ce que la plateforme sait de lui, réuni sur
# une page. Sert à préparer un entretien, ou à comprendre une situation avant
# de la commenter.
class Teacher::EtudiantsController < ApplicationController
  def show
    @eleve = User.where(teacher: nil).find(params[:id])
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
end
