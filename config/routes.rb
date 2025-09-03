Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  devise_for :users
  get "up" => "rails/health#show", as: :rails_health_check
  get '/legal', to: 'pages#legal', as: 'legal'
  #get '/prog_router', to: 'cw_nicknames#router', as: 'prog_router'
  get '/project_router', to: 'projects#router', as: 'project_router'  
  patch '/update_card_position', to: 'cards#position', as: 'card_position'

  root to: 'pages#home'
  resources :users, only: [:update]
  resources :projects, only: [:index, :show]
  resources :ratings, only: [:update]
  #resources :cw_nicknames, only: [:edit, :update]
  #resources :tickets, only: [:index, :create, :update, :destroy]
  
  resources :teams, only: [:new, :create, :show, :update] do
    #resources :messages, only: [:create, :index]
    resource :meetings, only: [:update]
  end

  resources :lists, only: [] do
    resources :cards, only: [:create, :update, :destroy], shallow: true
  end
  
  resources :cards, only: [] do
    resources :assignments, only: [:create, :destroy], shallow: true
  end
  
  namespace :teacher do
    resources :teams, only: [:index, :show, :update]
    resources :batches, only: [] do
      resources :teams, only: [:index]
    end
    #resources :messages, only: [:index, :create]
  end
  
  # resources :courses, only: :show do
  #   resources :exercices, only: :index
  # end

  # resources :exercices, only: [] do
  #   resources :attempts, only: [:create]
  # end

  #resources :exam_nicknames, only: [:create]
end
