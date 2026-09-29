# Ce que les étudiants demandent comme soutien, par matière.
class Teacher::SoutiensController < ApplicationController
  def show
    authorize [:teacher, :soutien], :show?
    charger
  end

  # Récapitulatif chiffré, réservé à l'administration : c'est la vue qui sert à
  # décider quelles séances ouvrir, pas à contacter les étudiants.
  def recap
    authorize [:teacher, :soutien], :recap?
    charger(defaut: "LSPI 2026-2029")
  end

  private

  def charger(defaut: nil)
    @batches = current_user.admin ? Batch.order(:title).to_a : current_user.supervised_batches.to_a
    @batches = Batch.order(:title).to_a if @batches.empty?
    @batch = if params[:batch_id].present?
               Batch.find(params[:batch_id])
             elsif defaut
               @batches.find { |b| b.title == defaut } || @batches.last
             else
               @batches.last
             end
    @soutien = Soutien.new(@batch)
  end
end
