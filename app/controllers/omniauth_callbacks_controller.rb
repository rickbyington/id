# frozen_string_literal: true

class OmniauthCallbacksController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :google_oauth2, :github, :failure ]

  def google_oauth2
    auth = request.env["omniauth.auth"]
    unless auth&.dig("info", "email").present?
      redirect_to new_user_session_path, alert: "Google did not provide an email."
      return
    end

    user = find_or_create_user_from_google(auth)
    sign_in(user, event: :authentication)
    redirect_to stored_location_for(:user) || root_path, notice: "Signed in with Google."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to new_user_session_path, alert: "Could not sign in: #{e.message}"
  end

  def github
    auth = request.env["omniauth.auth"]
    email = email_from_github(auth)
    unless email.present?
      redirect_to new_user_session_path, alert: "GitHub did not provide an email (make sure it's public or grant access)."
      return
    end

    user = find_or_create_user_from_github(auth, email)
    sign_in(user, event: :authentication)
    redirect_to stored_location_for(:user) || root_path, notice: "Signed in with GitHub."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to new_user_session_path, alert: "Could not sign in: #{e.message}"
  end

  def failure
    redirect_to new_user_session_path, alert: "Sign in was cancelled or failed."
  end

  private

  def find_or_create_user_from_google(auth)
    info = auth["info"]
    email = info["email"].downcase.strip

    user = User.find_by(email: email)
    return user if user

    password = SecureRandom.hex(32)
    user = User.new(
      email: email,
      first_name: info["first_name"].presence,
      last_name: info["last_name"].presence,
      password: password,
      password_confirmation: password
    )
    user.skip_confirmation!
    user.save!
    user
  end

  def email_from_github(auth)
    info = auth["info"]
    return info["email"].to_s.strip.presence if info["email"].present?

    # GitHub may put email in extra.raw_info or we need to fetch from /user/emails
    auth.dig("extra", "raw_info", "email").to_s.strip.presence
  end

  def find_or_create_user_from_github(auth, email)
    email = email.downcase.strip
    user = User.find_by(email: email)
    return user if user

    info = auth["info"]
    name = info["name"].to_s.strip
    first_name, last_name = name.present? ? name.split(" ", 2) : [ nil, nil ]

    password = SecureRandom.hex(32)
    user = User.new(
      email: email,
      first_name: first_name.presence,
      last_name: last_name.presence,
      password: password,
      password_confirmation: password
    )
    user.skip_confirmation!
    user.save!
    user
  end
end
