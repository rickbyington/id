# frozen_string_literal: true

Rails.application.config.to_prepare do
  require Rails.root.join("lib/doorkeeper_omit_id_token_for_client_credentials")
  Doorkeeper::OAuth::TokenResponse.prepend(DoorkeeperOmitIdTokenForClientCredentials)
end
