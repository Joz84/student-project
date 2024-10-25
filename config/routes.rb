Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  devise_for :users
  get "up" => "rails/health#show", as: :rails_health_check
  get '/legal', to: 'pages#legal', as: 'legal'
  get '/prog_router', to: 'programmations#router', as: 'prog_router'
  get '/project_router', to: 'projects#router', as: 'project_router'  
  root to: "pages#home"
  resources :users, only: :update
  resources :teams, only: [:new, :create]
  resources :projects, only: [:index, :show]

end
