class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  
  include Pundit::Authorization
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  
  #after_action :verify_authorized, unless: :skip_pundit?
  after_action :verify_authorized, except: :index, unless: :skip_pundit?
  after_action :verify_policy_scoped, only: :index, unless: :skip_pundit?

  def active_admin_controller?
    is_a?(ActiveAdmin::BaseController)
  end

  def skip_pundit?
    devise_controller? || params[:controller] =~ /(^(rails_)?admin)|(^pages$)/ || active_admin_controller?
  end

  def user_not_authorized
    flash[:alert] = "Vous n'êtes pas autorisé à réaliser cette action."
    redirect_to(root_path)
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [
      :first_name, 
      :last_name, 
      :student_number,
      :cw_nickname
      ])
    devise_parameter_sanitizer.permit(:account_update, keys: [
      :first_name, 
      :last_name, 
      :student_number,
      :cw_nickname
      ])
  end

  def active_course
    Course.where(ticket_activation: true).last
  end

  def default_course
    Course.find_by(id: session[:course_id]) || 
    active_course ||
    Course.find_by(position: 1)
  end

  # protected

  # def authenticate_user!
  #   if user_signed_in?
  #     super
  #   else
  #     redirect_to new_user_registration_path, :notice => 'Crée toi un compte.'
  #   end
  # end

end
