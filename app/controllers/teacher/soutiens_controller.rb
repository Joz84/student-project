# Le soutien tutoré, vu de l'administration : qui en demande, et où en sont
# les étudiants dans ce qu'ils déclarent.
class Teacher::SoutiensController < ApplicationController
  def show
    authorize [:teacher, :soutien], :show?
    charger
    @soutien = Soutien.new(@batch)
  end

  # L'avancement déclaré : ce que les étudiants ont rempli de leur niveau et de
  # leur travail personnel. Une mesure d'usage autant que de niveau.
  def avancement
    authorize [:teacher, :soutien], :avancement?
    charger
    @avancement = AvancementEtudiants.new(@batch)
  end

  private

  def charger
    @batches = Batch.where(id: Ue.select(:batch_id)).order(:title).to_a
    @batches = Batch.order(:title).to_a if @batches.empty?
    @batch = if params[:batch_id].present?
               Batch.find(params[:batch_id])
             else
               @batches.find { |b| b.title == "LSPI 2026-2029" } || @batches.last
             end
  end
end
