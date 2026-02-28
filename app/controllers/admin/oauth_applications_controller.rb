# frozen_string_literal: true

module Admin
  class OauthApplicationsController < BaseController
    # Optional scopes only; openid is always included when saving (required for OIDC)
    AVAILABLE_SCOPES = (defined?(DOORKEEPER_OPTIONAL_SCOPES) ? DOORKEEPER_OPTIONAL_SCOPES : %w[profile email]).freeze

    before_action :set_application, only: %i[show edit update destroy]
    before_action :set_available_scopes, only: %i[new create edit update]

    def index
      @oauth_applications = Doorkeeper::Application.order(created_at: :desc)
    end

    def show
    end

    def new
      @oauth_application = Doorkeeper::Application.new
    end

    def create
      @oauth_application = Doorkeeper::Application.new(application_params)
      if @oauth_application.save
        redirect_to admin_oauth_application_path(@oauth_application), notice: "Application was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @oauth_application.update(application_params)
        redirect_to admin_oauth_application_path(@oauth_application), notice: "Application was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @oauth_application.destroy
      redirect_to admin_oauth_applications_path, notice: "Application was successfully deleted."
    end

    private

    def set_application
      @oauth_application = Doorkeeper::Application.find(params[:id])
    end

    def set_available_scopes
      @available_scopes = self.class::AVAILABLE_SCOPES
    end

    def application_params
      p = params.require(:application).permit(:name, :redirect_uri, :confidential, :auto_approve, scopes: [], login_methods: [])
      scopes = params.dig(:application, :scopes)
      selected = scopes.is_a?(Array) ? scopes.reject(&:blank?) : scopes.to_s.split
      p[:scopes] = ([ "openid" ] + selected).uniq.join(" ")
      login_methods = params.dig(:application, :login_methods)
      p[:login_methods] = (login_methods.is_a?(Array) ? login_methods.reject(&:blank?) : login_methods.to_s.split(",").map(&:strip)).presence&.join(",") || "email"
      p
    end
  end
end
