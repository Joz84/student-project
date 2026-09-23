class CardSkillsController < ApplicationController
  def create
    @card = Card.find(params[:card_id])
    ids = Array(params.dig(:card_skill, :skill_ids)).reject(&:blank?)
    ajoutees = 0
    ids.each do |skill_id|
      lien = CardSkill.new(card: @card, skill_id: skill_id)
      authorize lien
      next if CardSkill.exists?(card_id: @card.id, skill_id: skill_id)
      ajoutees += 1 if lien.save
    end
    authorize CardSkill.new(card: @card) if ids.empty?
    redirect_to volet(@card.team, @card.id, "competences"),
                notice: ajoutees.zero? ? nil : "#{ajoutees} compétence#{'s' if ajoutees > 1} ajoutée#{'s' if ajoutees > 1}."
  end

  def destroy
    @card_skill = CardSkill.find(params[:id])
    authorize @card_skill
    carte = @card_skill.card
    @card_skill.destroy
    redirect_to volet(carte.team, carte.id, "competences")
  end

  private

  def volet(team, card_id, nom)
    team_path(team, carte: card_id, volet: nom, anchor: "carte#{card_id}")
  end
end
