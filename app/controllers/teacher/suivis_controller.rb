# Qui tient sa feuille d'appel. Réservé à l'administration : c'est un suivi de
# l'usage de l'outil, pas une information de travail entre collègues.
class Teacher::SuivisController < ApplicationController
  def show
    authorize [:teacher, :suivi], :show?
    @batches = Batch.joins(:lessons).distinct.order(:title).to_a
    @batch = params[:batch_id].present? ? Batch.find(params[:batch_id]) : @batches.last
    @suivi = SuiviEmargement.new(@batch) if @batch
  end
end
