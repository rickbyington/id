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
  devise_for :users,
    path: "",
    path_names: {
      sign_in: "signin",
      sign_up: "signup",
      sign_out: "signout",
      password: "password",
      confirmation: "confirmation",
      unlock: "unlock"
    },
    controllers: {
      sessions:       "users/sessions",
      registrations: "users/registrations",
      confirmations: "users/confirmations"
    }

  # Phone OTP sign-in
  scope "/users" do
    get  "signin/phone",        to: "users/phone_sessions#new",     as: :new_phone_session
    post "signin/phone",        to: "users/phone_sessions#create",  as: :phone_session
    get  "signin/phone/verify", to: "users/phone_sessions#verify",  as: :verify_phone_session
    post "signin/phone/verify", to: "users/phone_sessions#confirm", as: :confirm_phone_session

    # Phone OTP sign-up
    get  "signup/phone",        to: "users/phone_registrations#new",     as: :new_phone_registration
    post "signup/phone",        to: "users/phone_registrations#create",  as: :phone_registration
    get  "signup/phone/verify", to: "users/phone_registrations#verify",  as: :verify_phone_registration
    post "signup/phone/verify", to: "users/phone_registrations#confirm", as: :confirm_phone_registration
    get  "signup/phone/resend", to: "users/phone_registrations#resend",  as: :resend_phone_registration
  end

  # Change or add phone number (signed-in users; OTP to new number)
  get    "account/phone",         to: "users/phone_changes#new",      as: :new_user_phone_change
  post   "account/phone",         to: "users/phone_changes#create",   as: :user_phone_change
  get    "account/phone/verify",  to: "users/phone_changes#verify",   as: :verify_user_phone_change
  post   "account/phone/verify",  to: "users/phone_changes#confirm", as: :confirm_user_phone_change
  get    "account/phone/resend",  to: "users/phone_changes#resend",   as: :resend_user_phone_change

  # Change password (signed-in users; current password required)
  get   "account/password", to: "users/password_changes#edit",   as: :edit_user_password_change
  put   "account/password", to: "users/password_changes#update", as: :user_password_change
  patch "account/password", to: "users/password_changes#update"

  get "signup/check-email", to: "users/confirmations_pending#show", as: :signup_check_email

  get "up" => "rails/health#show", as: :rails_health_check
  root to: "home#index"

  get "mailbox", to: "test_deliveries#index", as: :mailbox
  delete "mailbox/clear", to: "test_deliveries#clear", as: :clear_mailbox
  get "mailbox/:id", to: "test_deliveries#show", as: :mailbox_delivery
  delete "authorized_applications/:application_id", to: "home#revoke_application", as: :revoke_authorized_application

  get "auth/google_oauth2/callback", to: "omniauth_callbacks#google_oauth2"
  get "auth/github/callback", to: "omniauth_callbacks#github"
  get "auth/failure", to: "omniauth_callbacks#failure"
end
