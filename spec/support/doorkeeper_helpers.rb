# frozen_string_literal: true

module DoorkeeperHelpers
  def create_oauth_application(**attrs)
    Doorkeeper::Application.create!(
      {
        name: "Test App",
        redirect_uri: "https://example.com/callback",
        scopes: "openid profile email",
        uid: SecureRandom.hex(8),
        secret: SecureRandom.hex(16)
      }.merge(attrs)
    )
  end

  def create_access_token_for(user, application: nil, scopes: "openid")
    application ||= create_oauth_application
    Doorkeeper::AccessToken.create!(
      application_id: application.id,
      resource_owner_id: user.id,
      scopes: scopes,
      expires_in: 7200
    )
  end

  def auth_headers_for(user, application: nil)
    token = create_access_token_for(user, application: application)
    # Doorkeeper stores the token string in the token attribute (JWT string when using doorkeeper-jwt)
    raw_token = token.respond_to?(:token) ? token.token : token.to_s
    { "Authorization" => "Bearer #{raw_token}", "Content-Type" => "application/json" }
  end
end

RSpec.configure do |config|
  config.include DoorkeeperHelpers, type: :request
end
