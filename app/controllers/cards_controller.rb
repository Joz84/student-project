class CardsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :position

  def create
    @card = Card.new(card_params)
    @list = List.find(params[:list_id])
    @card.list = @list
    authorize @card
    @team = @card.team
    if card_params[:teacher_validation].present? && !current_user.teacher?
      flash[:alert] = "Vous n'êtes pas autorisé à créer cette tâche."
    elsif @card.save
      redirect_to @team, status: :see_other
    else
      @assignment = Assignment.new
      @meeting = Meeting.new
      @all_skills = @team.project.batch.current_referential.skills
      render "teams/show", status: :unprocessable_entity
    end
  end

  def update
    @card = Card.find(params[:id])
    authorize @card
    @team = @card.team
    if card_params[:teacher_validation].present? && !current_user.teacher?
      flash[:alert] = "Vous n'êtes pas autorisé à valider cette tâche."
    elsif !@card.update(card_params)
      flash[:alert] = @card.errors.messages.map{|k, v| "#{k.capitalize} #{v.join('et ')}"}.join(". ")
    end
    # Une carte se modifie depuis le tableau comme depuis la feuille de route :
    # on revient là où l'on était. Depuis le tableau, on revient sur le volet
    # d'où l'on vient, ouvert : sans cela le panneau se refermait et la
    # modification semblait n'avoir pas été prise en compte.
    if params[:volet].present?
      redirect_to team_path(@team, carte: @card.id, volet: params[:volet],
                            anchor: "carte#{@card.id}"),
                  notice: flash[:alert] ? nil : "Tâche modifiée.", status: :see_other
    else
      redirect_back fallback_location: @team, status: :see_other
    end
  end

  def destroy
    @card = Card.find(params[:id])
    authorize @card
    @team = @card.team
    @card.destroy
    redirect_to @team, status: :see_other
  end

  def position
    @card = Card.find(params[:id].to_i)
    authorize @card
    @old_list = List.find(params[:old_list].to_i)
    @new_list = List.find(params[:new_list].to_i)
    @card.update(list: @new_list)
    @card.insert_at(params[:new_index].to_i + 1)
    if @card.begin_at.nil? && @card.end_at.nil? && @card.list.position == 1
      @card.update(begin_at: DateTime.now)
    elsif @card.end_at.nil? && @card.list.position == 2
      @card.update(end_at: DateTime.now)
    else
    end
    respond_to do |format|
      format.json { 
        render :plain => {
          begin_at:@card.str_begin_at, 
          end_at:@card.str_end_at
        }.to_json, 
        status: 200, 
        content_type: 'application/json'
      }
    end
  end

  private

  def card_params
    params.require(:card).permit(
      :name, 
      :description, 
      :drive_link,
      :status,
      :teacher_validation,
      :milestone_id,
      :time_estimate,
      :time_unit
    )
  end
end
