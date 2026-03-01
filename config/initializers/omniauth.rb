# frozen_string_literal: true

# OmniAuth: Google and GitHub (for Sign in with Google/GitHub identity).
# Set GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET, GITHUB_CLIENT_ID, GITHUB_CLIENT_SECRET in ENV.
Rails.application.config.middleware.use OmniAuth::Builder do
  google_id = ENV["GOOGLE_CLIENT_ID"].presence
  google_secret = ENV["GOOGLE_CLIENT_SECRET"].presence
  if google_id.present? && google_secret.present?
    provider :google_oauth2,
      google_id,
      google_secret,
      scope: "userinfo.email userinfo.profile",
      prompt: "consent"
  else
    Rails.logger.warn "[OmniAuth] Google missing (GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET). Sign in with Google will not be shown."
  end

  github_id = ENV["GITHUB_CLIENT_ID"].presence
  github_secret = ENV["GITHUB_CLIENT_SECRET"].presence
  if github_id.present? && github_secret.present?
    provider :github,
      github_id,
      github_secret,
      scope: "user:email"
  else
    Rails.logger.warn "[OmniAuth] GitHub missing (GITHUB_CLIENT_ID, GITHUB_CLIENT_SECRET). Sign in with GitHub will not be shown."
  end
end

OmniAuth.config.allowed_request_methods = %i[ get ]
OmniAuth.config.silence_get_warning = true

# Google rejects redirect_uri with 0.0.0.0. Use localhost in development so the callback URL is allowed.
if Rails.env.development? && ENV["OMNIAUTH_FULL_HOST"].blank?
  OmniAuth.config.full_host = "http://localhost:3000"
elsif ENV["OMNIAUTH_FULL_HOST"].present?
  OmniAuth.config.full_host = ENV["OMNIAUTH_FULL_HOST"]
end
