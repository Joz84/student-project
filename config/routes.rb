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
  resources :users, only: [:update] do
    resources :user_skill_statuses, only: [:update], param: :skill_id
  end
  resource :speciality, only: [:edit, :update]
  resources :projects, only: [:index, :show]
  resources :ratings, only: [:update]
  resources :ues, only: [] do
    resource :assessment, only: [:update], controller: "ue_assessments"
  end
  #resources :cw_nicknames, only: [:edit, :update]
  #resources :tickets, only: [:index, :create, :update, :destroy]

  # Émargement : l'étudiant se signale présent, l'enseignant tient la liste.
  resources :lessons, only: [] do
    resource :attendance, only: [:create]
  end

  resources :teams, only: [:new, :create, :show, :update] do
    #resources :messages, only: [:create, :index]
    resources :progressions, only: [:index]
    resources :meetings, only: [:create, :update, :destroy]
    resource :roadmap, only: [:show]
    resource :matieres, only: [:show], controller: "matieres"
    resources :milestones, only: [:create, :update, :destroy] do
      member do
        patch :monter
        patch :descendre
      end
    end
  end

  resources :lists, only: [] do
    resources :cards, only: [:create, :update, :destroy], shallow: true
  end
  
  resources :cards, only: [] do
    resources :assignments, only: [:create, :destroy], shallow: true
    resources :card_skills, only: [:create, :destroy], shallow: true    
  end
  
  namespace :teacher do
    resource :bilan, only: [:show, :update], controller: "bilans" do
      get  :export
      post :import
    end
    resources :lessons, only: [:show] do
      member do
        get  :liste
        post :ouvrir
        post :verrouiller
        post :deverrouiller
        post :rouvrir
        post :valider
      end
      resources :attendances, only: [:create, :update, :destroy]
    end
    resources :teams, only: [:index, :show, :update]
    resources :batches, only: [] do
      resources :teams, only: [:index] do
        collection do
          get :solver_payload
          post :import
        end
      end
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
