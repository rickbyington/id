Rails.application.routes.draw do
  namespace :admin do
    root to: "oauth_applications#index"
    resources :oauth_applications
    resources :permissions
    resources :users
    resources :user_permissions
  end

  use_doorkeeper_openid_connect
  use_doorkeeper
  devise_for :users, path: "", path_names: {
    sign_in: "signin",
    sign_up: "signup",
    sign_out: "signout",
    password: "password",
    confirmation: "confirmation",
    unlock: "unlock"
  }

  get "up" => "rails/health#show", as: :rails_health_check
  root to: "home#index"
  delete "authorized_applications/:application_id", to: "home#revoke_application", as: :revoke_authorized_application
end
