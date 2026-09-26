# Ce que les étudiants demandent comme soutien, par matière.
class Teacher::SoutiensController < ApplicationController
  def show
    authorize [:teacher, :soutien], :show?
    @batches = current_user.admin ? Batch.order(:title).to_a : current_user.supervised_batches.to_a
    @batches = Batch.order(:title).to_a if @batches.empty?
    @batch = params[:batch_id].present? ? Batch.find(params[:batch_id]) : @batches.last
    @soutien = Soutien.new(@batch)
  end
end
