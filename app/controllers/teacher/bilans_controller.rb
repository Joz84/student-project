# Bilan de présences : une grille par UE, séances en colonnes, étudiants en
# lignes. Affichage, export et import partagent la même grille.
class Teacher::BilansController < ApplicationController
  before_action :autoriser
  before_action :charger_grille, except: [:import]

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
end
