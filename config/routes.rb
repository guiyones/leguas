Rails.application.routes.draw do
  root "home#show"

  resource :session, only: %i[ new destroy ]
  resources :auth_tokens, only: :create
  namespace :auth_tokens do
    resource :validations, only: %i[ new create ]
  end

  resources :walks

  get "up" => "rails/health#show", as: :rails_health_check
end
