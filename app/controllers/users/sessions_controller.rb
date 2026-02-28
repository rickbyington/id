# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  include ApplicationHelper

  def new
    if redirect_to_single_oauth?
      redirect_to single_oauth_path, allow_other_host: false
      return
    end
    self.resource = resource_class.new(sign_in_params)
    render "devise/sessions/new"
  end

  private

  def redirect_to_single_oauth?
    login_methods = login_methods_for_pending_oauth_client
    return false if login_methods.empty?

    show_email  = login_methods.include?("email")
    show_phone  = login_methods.include?("phone")
    return false if show_email || show_phone

    show_google = login_methods.include?("google") && omniauth_google_configured?
    show_github = login_methods.include?("github") && omniauth_github_configured?
    [ show_google, show_github ].one?
  end

  def single_oauth_path
    login_methods = login_methods_for_pending_oauth_client
    show_google = login_methods.include?("google") && omniauth_google_configured?
    show_github = login_methods.include?("github") && omniauth_github_configured?
    return "/auth/google_oauth2" if show_google && !show_github
    return "/auth/github" if show_github && !show_google

    new_user_session_path
  end
end
