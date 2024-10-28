class TicketsController < ApplicationController
  def index
    @tickets = policy_scope(Ticket).where(course: active_course)
                                   .where
                                   .not(progress: :archived)
                                   .order(created_at: :desc)
    @ticket = Ticket.new
    @course = active_course
    render layout: "courses_sidebar_layout"
  end

  def create
    @ticket = Ticket.new(ticket_params)
    @ticket.user = current_user
    authorize @ticket
    if @ticket.save
      redirect_to tickets_path
    else
      @course = active_course
      @tickets = policy_scope(Ticket).where(course: active_course)
                                     .where
                                     .not(progress: :archived)
                                     .order(created_at: :desc)
      render :index, status: :unprocessable_entity, layout: "courses_sidebar_layout"
    end
  end

  def update
    @ticket = Ticket.find(params[:id])
    authorize @ticket
    if @ticket.update(ticket_params)
      redirect_to tickets_path
    else
      render :index, status: :unprocessable_entity, layout: "courses_sidebar_layout"
    end
  end

  def destroy
    @ticket = Ticket.find(params[:id])
    authorize @ticket
    @ticket.destroy
    redirect_to tickets_path
  end

  private

  def ticket_params
    params.require(:ticket).permit(:content, :progress)
  end
end
