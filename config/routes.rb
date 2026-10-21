Rails.application.routes.draw do
  root "menus#show"

  resource :session, only: %i[ new destroy ]
  resources :auth_tokens, only: :create
  namespace :auth_tokens do
    resource :validations, only: %i[ new create ]
  end

  resource :traveler, only: %i[ new create ]
  resource :profile, only: %i[ edit update ]

  resources :walks
  resources :stair_sessions, except: %i[ index show ]
  resource :celebration, only: %i[ show create ]
  resource :map, only: :show
  resource :menu, only: :show
  resource :phase, only: :show

  get "up" => "rails/health#show", as: :rails_health_check
end
