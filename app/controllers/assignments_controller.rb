class AssignmentsController < ApplicationController
  def destroy
    @assignment = Assignment.find(params[:id])
    authorize @assignment
    @team = @assignment.team
    card_id = @assignment.card_id
    @assignment.destroy
    redirect_to volet(@team, card_id, "collaborateurs")
  end

  # Plusieurs collaborateurs d'un coup : ajouter les membres d'une équipe un
  # par un, avec un rechargement à chaque fois, n'avait pas de sens.
  def create
    @card = Card.find(params[:card_id])
    ids = Array(params.dig(:assignment, :user_ids)).reject(&:blank?)
    ajoutes = 0
    ids.each do |user_id|
      affectation = Assignment.new(card: @card, user_id: user_id)
      authorize affectation
      next if Assignment.exists?(card_id: @card.id, user_id: user_id)
      ajoutes += 1 if affectation.save
    end
    authorize Assignment.new(card: @card) if ids.empty?
    redirect_to volet(@card.team, @card.id, "collaborateurs"),
                notice: message(ajoutes, "collaborateur")
  end

  private

  # On revient sur la carte, volet ouvert : sans cela l'accordéon se referme
  # et l'on ne voit pas le résultat de ce qu'on vient de faire.
  def volet(team, card_id, nom)
    team_path(team, carte: card_id, volet: nom, anchor: "carte#{card_id}")
  end

  def message(n, mot)
    return nil if n.zero?
    "#{n} #{mot}#{'s' if n > 1} ajouté#{'s' if n > 1}."
  end
end
