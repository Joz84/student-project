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

  # Quand toute la classe est là, renseigner les lignes une par une est une
  # perte de temps. Seuls les étudiants sans pointage sont touchés : une
  # absence déjà saisie ne doit pas être effacée par un raccourci.
  def tous_presents
    if @lesson.valide?
      return redirect_to teacher_lesson_path(@lesson), status: :see_other,
                         alert: "L'appel est validé : rouvrez-le pour le modifier."
    end

    ajoutes = 0
    ActiveRecord::Base.transaction do
      @lesson.eleves_attendus.each do |eleve|
        pointage = @lesson.pointage_de(eleve)
        next if pointage.persisted?
        pointage.update!(status: :present, declared_by: :teacher, declared_at: Time.current)
        ajoutes += 1
      end
    end

    message = if ajoutes.zero?
                "Tous les étudiants étaient déjà renseignés : rien n'a changé."
              else
                "#{ajoutes} étudiant#{'s' if ajoutes > 1} marqué#{'s' if ajoutes > 1} présent#{'s' if ajoutes > 1}."
              end
    redirect_to teacher_lesson_path(@lesson), notice: message, status: :see_other
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
