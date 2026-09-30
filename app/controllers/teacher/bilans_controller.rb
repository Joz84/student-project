# Bilan de présences : une grille par UE, séances en colonnes, étudiants en
# lignes. Affichage, export et import partagent la même grille.
class Teacher::BilansController < ApplicationController
  before_action :autoriser
  before_action :charger_grille, except: [:import, :eleve]

  def show
  end

  def update
    modifiees = 0
    ActiveRecord::Base.transaction do
      (params[:statuts] || {}).each do |lesson_id, par_eleve|
        lesson = @sheet.lessons.find { |l| l.id.to_s == lesson_id.to_s } or next
        par_eleve.each do |user_id, statut|
          modifiees += 1 if appliquer(lesson, user_id, statut)
        end
      end

      (params[:invites] || {}).each_value do |ligne|
        (ligne[:statuts] || {}).each do |lesson_id, statut|
          lesson = @sheet.lessons.find { |l| l.id.to_s == lesson_id.to_s } or next
          modifiees += 1 if appliquer_invite(lesson, ligne, statut)
        end
      end
    end
    redirect_to teacher_bilan_path(ue_id: @ue&.id),
                notice: "#{modifiees} case#{'s' if modifiees > 1} enregistrée#{'s' if modifiees > 1}.", status: :see_other
  end

  def export
    send_data AttendanceSheetExport.new(@sheet).to_csv,
              filename: "presences-#{@ue&.name.to_s.parameterize}-#{Date.current}.csv",
              type: "text/csv; charset=utf-8"
  end

  def import
    @ue = Ue.find(params[:ue_id])
    sheet = AttendanceSheet.new(teacher: current_user, ue: @ue)
    if params[:fichier].blank?
      return redirect_to teacher_bilan_path(ue_id: @ue.id), alert: "Aucun fichier sélectionné.", status: :see_other
    end

    resultat = AttendanceSheetImport.new(sheet, params[:fichier]).run
    if resultat.erreurs.any?
      redirect_to teacher_bilan_path(ue_id: @ue.id),
                  alert: "Import interrompu — #{resultat.erreurs.first(3).join(' ; ')}", status: :see_other
    else
      redirect_to teacher_bilan_path(ue_id: @ue.id),
                  notice: "Import : #{resultat}", status: :see_other
    end
  end

  # Ajoute une personne sans compte à la liste de la matière. Elle apparaît
  # alors dans la grille, sans être encore pointée nulle part — c'est
  # précisément ce qu'un pointage seul ne permettait pas d'exprimer.
  def eleve
    @ue = Ue.find(params[:ue_id])
    # Portée : attendu à chaque séance de la matière, ou seulement présent dans
    # ce relevé, pour une personne venue une fois.
    permanent = params[:portee] != "releve"

    invite = UeGuest.new(ue: @ue, permanent: permanent,
                         first_name: params[:guest_first_name].to_s.strip,
                         last_name: params[:guest_last_name].to_s.strip,
                         student_number: params[:guest_student_number].to_s.strip)

    if invite.save
      suite = permanent ? "Il sera attendu à chaque séance." : "Il ne figure que dans ce relevé."
      redirect_to teacher_bilan_path(ue_id: @ue.id), status: :see_other,
                  notice: "#{invite.nom_complet} ajouté à la liste de #{@ue.name}. #{suite}"
    else
      redirect_to teacher_bilan_path(ue_id: @ue.id), status: :see_other,
                  alert: invite.errors.full_messages.to_sentence
    end
  end

  private

  def autoriser
    authorize %i[teacher bilan], "#{action_name}?".to_sym
  end

  def charger_grille
    @ues = AttendanceSheet.ues_de(current_user)
    @ue = params[:ue_id].present? ? @ues.find_by(id: params[:ue_id]) : @ues.first
    @sheet = AttendanceSheet.new(teacher: current_user, ue: @ue) if @ue
  end

  # Une case laissée vide efface le pointage : le bilan doit pouvoir revenir
  # en arrière, pas seulement ajouter.
  def appliquer(lesson, user_id, statut)
    existant = Attendance.find_by(lesson_id: lesson.id, user_id: user_id)
    if statut.blank?
      return false if existant.nil?
      existant.destroy!
      return true
    end
    return false if existant&.status == statut
    (existant || Attendance.new(lesson_id: lesson.id, user_id: user_id))
      .update!(status: statut, declared_by: :teacher, declared_at: Time.current)
    true
  end

  # Même logique pour une ligne sans compte, retrouvée sur sa clé plutôt que
  # sur un identifiant : c'est ce qui réunit une inscription faite ici et un
  # pointage pris pendant l'appel.
  def appliquer_invite(lesson, ligne, statut)
    cle = UeGuest.cle_de(ligne[:nom], ligne[:prenom], ligne[:numero])
    existant = Attendance.where(lesson_id: lesson.id, user_id: nil).find do |a|
      UeGuest.cle_de(a.guest_last_name, a.guest_first_name, a.guest_student_number) == cle
    end

    if statut.blank?
      return false if existant.nil?
      existant.destroy!
      return true
    end
    return false if existant&.status == statut

    (existant || Attendance.new(lesson_id: lesson.id,
                                guest_last_name: ligne[:nom], guest_first_name: ligne[:prenom],
                                guest_student_number: ligne[:numero]))
      .update!(status: statut, declared_by: :teacher, declared_at: Time.current)
    true
  end
end
