class CardSkillsController < ApplicationController

  def create
    @card_skill = CardSkill.new(card_skill_params)
    @card_skill.card = Card.find(params[:card_id])
    authorize @card_skill
    if @card_skill.save
      redirect_to team_path(@card_skill.card.team)
    else
      @team = @card_skill.card.team
      @card = Card.new
      @assignment = Assignment.new
      @meeting = Meeting.new
      @all_skills = @team.project.batch.current_referential.skills
      render "teams/show", status: :unprocessable_entity
    end
  end


  def destroy
    @card_skill = CardSkill.find(params[:id])
    authorize @card_skill
    @card_skill.destroy
    redirect_to team_path(@card_skill.card.team)
  end

  private

  def card_skill_params
    params.require(:card_skill).permit(:skill, :skill_id)
  end

end
