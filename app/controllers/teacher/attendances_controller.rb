class Teacher::AttendancesController < ApplicationController
  before_action :charger_seance

  # Pointage d'un étudiant, qu'il soit attendu ou venu en rattrapage.
  def update
    @attendance = @lesson.pointage_de(User.find(params[:id]))
    authorize [:teacher, @attendance]

    if params[:status].blank?
      # « Non renseigné » n'est pas un état : c'est l'absence de ligne.
      @attendance.destroy! if @attendance.persisted?
    else
      @attendance.update!(status: params[:status], declared_by: :teacher,
                          declared_at: Time.current)
    end
    redirect_to teacher_lesson_path(@lesson)
  end

  # Étudiant absent de toutes les listes : saisie libre, sans validation de
  # format, pour ne pas bloquer un enseignant devant sa classe.
  def create
    @attendance = @lesson.attendances.new(
      status: :present, declared_by: :teacher, declared_at: Time.current,
      guest_first_name: params[:guest_first_name].to_s.strip,
      guest_last_name: params[:guest_last_name].to_s.strip,
      guest_student_number: params[:guest_student_number].to_s.strip
    )
    authorize [:teacher, @attendance]

    if [@attendance.guest_first_name, @attendance.guest_last_name,
        @attendance.guest_student_number].all?(&:blank?)
      redirect_to teacher_lesson_path(@lesson), alert: "Renseignez au moins un nom ou un numéro."
    else
      @attendance.save!
      redirect_to teacher_lesson_path(@lesson),
                  notice: "#{@attendance.nom_complet} ajouté à la feuille d'appel."
    end
  end

  def destroy
    @attendance = @lesson.attendances.find(params[:id])
    authorize [:teacher, @attendance]
    @attendance.destroy!
    redirect_to teacher_lesson_path(@lesson)
  end

  private

  def charger_seance
    @lesson = Lesson.find(params[:lesson_id])
  end
end
