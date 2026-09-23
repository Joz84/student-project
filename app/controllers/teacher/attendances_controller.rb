class Teacher::AttendancesController < ApplicationController
  def update
    @lesson = Lesson.find(params[:lesson_id])
    @attendance = @lesson.pointage_de(User.find(params[:id]))
    authorize [:teacher, @attendance]

    @attendance.assign_attributes(status: params[:status], declared_by: :teacher,
                                  declared_at: Time.current)
    @attendance.save!
    redirect_to teacher_lesson_path(@lesson)
  end
end
