# Feuille d'appel tenue par l'enseignant.
class Teacher::LessonsController < ApplicationController
  before_action :charger

  def show
  end

  # Rafraîchissement de la liste, appelé toutes les cinq secondes par le
  # navigateur : l'enseignant voit les étudiants se signaler au fil de l'eau.
  def liste
    render partial: "teacher/lessons/liste", locals: { lesson: @lesson }
  end

  def ouvrir
    @lesson.ouvrir_pointage!
    redirect_to teacher_lesson_path(@lesson),
                notice: "Appel ouvert. Code à afficher : #{@lesson.attendance_code}", status: :see_other
  end

  def verrouiller
    @lesson.verrouiller!
    redirect_to teacher_lesson_path(@lesson), notice: "Pointages figés.", status: :see_other
  end

  def deverrouiller
    @lesson.deverrouiller!
    redirect_to teacher_lesson_path(@lesson), notice: "Les étudiants peuvent à nouveau se signaler.", status: :see_other
  end

  def rouvrir
    if @lesson.rouvrable?
      @lesson.rouvrir!
      redirect_to teacher_lesson_path(@lesson),
                  notice: "Appel rouvert : les étudiants peuvent à nouveau se signaler.", status: :see_other
    else
      redirect_to teacher_lesson_path(@lesson),
                  alert: "Le créneau est terminé. Corrigez depuis le bilan de présences.", status: :see_other
    end
  end

  def valider
    # Les attendus qui ne se sont pas signalés sont portés absents : sans cela
    # la séance resterait à moitié renseignée.
    ActiveRecord::Base.transaction do
      @lesson.eleves_attendus.each do |eleve|
        p = @lesson.pointage_de(eleve)
        p.status ||= :absent
        p.declared_by = :teacher if p.new_record?
        p.save!
      end
      @lesson.valider!
    end
    redirect_to teacher_lesson_path(@lesson),
                notice: "Appel validé : #{@lesson.presents_count} présents.", status: :see_other
  end

  private

  def charger
    @lesson = Lesson.find(params[:id])
    authorize [:teacher, @lesson]
  end
end
