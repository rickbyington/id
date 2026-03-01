class HomeController < ApplicationController
  def index
    if !user_signed_in?
      redirect_to new_user_session_path
    else
      load_authorized_applications
    end
  end

  def revoke_application
    redirect_options = { status: :see_other }

    unless user_signed_in?
      redirect_to root_path, **redirect_options.merge(alert: "Not allowed.")
      return
    end

    application = Doorkeeper::Application.find_by(id: params[:application_id])
    unless application
      redirect_to root_path, **redirect_options.merge(alert: "Application not found.")
      return
    end

    revoked = Doorkeeper::AccessToken
      .where(resource_owner_id: current_user.id, application_id: application.id)
      .where(revoked_at: nil)
      .update_all(revoked_at: Time.current)

    if revoked.positive?
      redirect_to root_path, **redirect_options.merge(notice: "Access to #{application.name} has been revoked.")
    else
      redirect_to root_path, **redirect_options.merge(notice: "No active access for that application.")
    end
  end

  private

  def load_authorized_applications
    tokens = Doorkeeper::AccessToken
      .where(resource_owner_id: current_user.id)
      .where(revoked_at: nil)
      .includes(:application)
      .order(created_at: :desc)

    @authorized_applications = tokens
      .group_by(&:application_id)
      .map do |_app_id, app_tokens|
        token = app_tokens.first
        scopes = token.scopes.present? ? token.scopes.to_s.split : []
        { application: token.application, scopes: scopes, last_authorized_at: token.created_at }
      end
  end
end
