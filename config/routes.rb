Rails.application.routes.draw do
  root "home#show"

  resource :session, only: %i[ new destroy ]
  resources :auth_tokens, only: :create
  namespace :auth_tokens do
    resource :validations, only: %i[ new create ]
  end

  resource :traveler, only: %i[ new create ]
  resource :profile, only: %i[ edit update ]

  resources :walks
  resource :celebration, only: %i[ show create ]

  get "up" => "rails/health#show", as: :rails_health_check
end
