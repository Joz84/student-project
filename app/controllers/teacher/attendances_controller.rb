class Teacher::AttendancesController < ApplicationController
  before_action :charger_seance

  # Pointage d'un étudiant, qu'il soit attendu ou venu en rattrapage.
  def update
    eleve = User.find(params[:id])
    @attendance = @lesson.pointage_de(eleve)
    authorize [:teacher, @attendance]

    if params[:status].blank?
      # « Non renseigné » n'est pas un état : c'est l'absence de ligne.
      @attendance.destroy! if @attendance.persisted?
    else
      @attendance.update!(status: params[:status], declared_by: :teacher,
                          declared_at: Time.current)
    end

    message = inscrire_sur_la_matiere(user: eleve)
    redirect_to teacher_lesson_path(@lesson), notice: message, status: :see_other
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
      redirect_to teacher_lesson_path(@lesson), alert: "Renseignez au moins un nom ou un numéro.", status: :see_other
    else
      @attendance.save!
      suite = inscrire_sur_la_matiere(
        nom: @attendance.guest_last_name, prenom: @attendance.guest_first_name,
        numero: @attendance.guest_student_number
      )
      redirect_to teacher_lesson_path(@lesson), status: :see_other,
                  notice: "#{@attendance.nom_complet} ajouté à la feuille d'appel.#{" #{suite}" if suite}"
    end
  end

  def destroy
    @attendance = @lesson.attendances.find(params[:id])
    authorize [:teacher, @attendance]
    @attendance.destroy!
    redirect_to teacher_lesson_path(@lesson), status: :see_other
  end

  private

  # L'enseignant choisit la portée de sa saisie : cette séance seulement, ou
  # toute la matière. Le second cas inscrit la personne sur la liste de l'UE,
  # d'où elle sera attendue à chaque séance suivante.
  def inscrire_sur_la_matiere(user: nil, nom: nil, prenom: nil, numero: nil)
    return nil unless params[:portee] == "matiere"
    return nil if @lesson.ue_id.nil?

    invite = if user
               UeGuest.find_or_initialize_by(ue_id: @lesson.ue_id, user_id: user.id)
             else
               UeGuest.where(ue_id: @lesson.ue_id, user_id: nil).find { |g|
                 g.cle == UeGuest.cle_de(nom, prenom, numero)
               } || UeGuest.new(ue_id: @lesson.ue_id, last_name: nom,
                                first_name: prenom, student_number: numero)
             end

    invite.permanent = true
    return nil unless invite.changed? || invite.new_record?
    invite.save ? "Inscrit sur toute la matière." : nil
  end

  def charger_seance
    @lesson = Lesson.find(params[:lesson_id])
  end
end
