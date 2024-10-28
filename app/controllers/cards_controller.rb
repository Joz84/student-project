class CardsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :position

  def create
    @card = Card.new(card_params)
    @list = List.find(params[:list_id])
    @card.list = @list
    authorize @card
    @team = @card.team
    if @card.save
      redirect_to @team
    else
      @assignment = Assignment.new
      render "teams/show", status: :unprocessable_entity
    end
  end

  def update
    @card = Card.find(params[:id])
    authorize @card
    @team = @card.team
    flash[:alert] = @card.errors.messages.values.join(". ") if !@card.update(card_params)
    redirect_to @team
  end

  def destroy
    @card = Card.find(params[:id])
    authorize @card
    @team = @card.team
    @card.destroy
    redirect_to @team
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
      :drive_link
    )
  end
end
