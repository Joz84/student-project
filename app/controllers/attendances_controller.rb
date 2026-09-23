# Pointage par l'étudiant lui-même.
class AttendancesController < ApplicationController
  def create
    @lesson = Lesson.find(params[:lesson_id])
    @attendance = @lesson.pointage_de(current_user)
    authorize @attendance

    if !@lesson.en_cours?
      refus "Ce cours n'a pas lieu en ce moment."
    elsif !@lesson.pointage_ouvert?
      refus "L'appel n'est pas ouvert. Demande à ton enseignant de le lancer."
    elsif params[:code].to_s.strip != @lesson.attendance_code
      refus "Code incorrect. Il est affiché par ton enseignant."
    else
      @attendance.update!(status: :present, declared_by: :student,
                          declared_at: Time.current)
      redirect_to root_path, notice: "Ta présence est enregistrée pour « #{@lesson.title} ».", status: :see_other
    end
  end

  private

  def refus(message)
    redirect_to root_path, alert: message, status: :see_other
  end
end
