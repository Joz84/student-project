class RatingsController < ApplicationController

  def update
    @rating = Rating.find(params[:id])
    authorize @rating
    @rating.insert_at(rating_params[:position].to_i)
  end

  private

  def rating_params
    params.require(:rating).permit(:position)
  end
end
