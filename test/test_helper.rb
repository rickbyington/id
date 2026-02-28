# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require "simplecov"
SimpleCov.start "rails" do
  add_filter "/vendor/"
  add_filter "/test/"
end
require_relative "../config/environment"
require "rails/test_help"
require "devise/test/integration_helpers"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
    # Tests create their own data; no fixtures loaded by default.
  end
end

module ActionDispatch
  class IntegrationTest
    include Devise::Test::IntegrationHelpers

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

    def sign_in_via_form(user, password: "password123")
      post user_session_path, params: { user: { email: user.email, password: password } }
      follow_redirect! if response.redirect?
    end
  end
end
