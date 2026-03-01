# frozen_string_literal: true

require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  include ApplicationHelper

  # --- omniauth_google_configured? ---

  test "omniauth_google_configured? returns false when ENV has no google" do
    ENV.delete("GOOGLE_CLIENT_ID")
    ENV.delete("GOOGLE_CLIENT_SECRET")
    assert_equal false, omniauth_google_configured?
  end

  test "omniauth_google_configured? returns true when ENV vars are set" do
    ENV["GOOGLE_CLIENT_ID"] = "id"
    ENV["GOOGLE_CLIENT_SECRET"] = "secret"
    assert_equal true, omniauth_google_configured?
  end

  test "omniauth_google_configured? returns false when only id is set" do
    ENV["GOOGLE_CLIENT_ID"] = "id"
    ENV.delete("GOOGLE_CLIENT_SECRET")
    assert_equal false, omniauth_google_configured?
  end

  # --- omniauth_github_configured? ---

  test "omniauth_github_configured? returns false when ENV has no github" do
    ENV.delete("GITHUB_CLIENT_ID")
    ENV.delete("GITHUB_CLIENT_SECRET")
    assert_equal false, omniauth_github_configured?
  end

  test "omniauth_github_configured? returns true when ENV vars are set" do
    ENV["GITHUB_CLIENT_ID"] = "id"
    ENV["GITHUB_CLIENT_SECRET"] = "secret"
    assert_equal true, omniauth_github_configured?
  end

  test "omniauth_github_configured? returns false when only id is set" do
    ENV["GITHUB_CLIENT_ID"] = "id"
    ENV.delete("GITHUB_CLIENT_SECRET")
    assert_equal false, omniauth_github_configured?
  end

  # --- default_login_methods ---

  test "default_login_methods returns only email when env is not set" do
    clear_login_methods_env
    assert_equal %w[ email ], default_login_methods
  end

  test "default_login_methods returns only email when env is blank" do
    ENV["DEFAULT_LOGIN_METHODS"] = "   "
    clear_signalwire_env
    assert_equal %w[ email ], default_login_methods
  end

  test "default_login_methods parses comma-separated methods" do
    ENV["DEFAULT_LOGIN_METHODS"] = "email,google,github"
    assert_equal %w[ email google github ], default_login_methods
  end

  test "default_login_methods strips whitespace" do
    ENV["DEFAULT_LOGIN_METHODS"] = " email , google "
    assert_equal %w[ email google ], default_login_methods
  end

  test "default_login_methods returns only email when parsed list is empty" do
    ENV["DEFAULT_LOGIN_METHODS"] = ",,"
    assert_equal %w[ email ], default_login_methods
  end

  # --- signalwire_configured? ---

  test "signalwire_configured? returns false when no ENV vars are set" do
    clear_signalwire_env
    assert_equal false, signalwire_configured?
  end

  test "signalwire_configured? returns true when all four ENV vars are set" do
    ENV["SIGNALWIRE_PROJECT_ID"]   = "pid"
    ENV["SIGNALWIRE_API_TOKEN"]    = "tok"
    ENV["SIGNALWIRE_SPACE_URL"]     = "space.signalwire.com"
    ENV["SIGNALWIRE_FROM_NUMBER"]  = "+15551234567"
    assert_equal true, signalwire_configured?
  end

  test "signalwire_configured? returns false when only some ENV vars are set" do
    ENV["SIGNALWIRE_PROJECT_ID"]  = "pid"
    ENV["SIGNALWIRE_API_TOKEN"]   = "tok"
    ENV["SIGNALWIRE_SPACE_URL"]    = nil
    ENV["SIGNALWIRE_FROM_NUMBER"] = nil
    assert_equal false, signalwire_configured?
  end

  # --- login_methods_for_pending_oauth_client ---

  test "login_methods_for_pending_oauth_client returns [] when session return_to is blank" do
    assert_equal [], login_methods_for_pending_oauth_client
  end

  test "login_methods_for_pending_oauth_client returns app login_methods when session has oauth authorize URL with client_id" do
    app = Doorkeeper::Application.create!(
      name: "OAuth App",
      redirect_uri: "https://app.com/callback",
      scopes: "openid",
      uid: SecureRandom.hex(8),
      secret: SecureRandom.hex(16),
      login_methods: "email,google"
    )
    @controller.session[:user_return_to] = "http://example.com/oauth/authorize?client_id=#{app.uid}&redirect_uri=https%3A%2F%2Fapp.com%2Fcallback"
    assert_equal %w[ email google ], login_methods_for_pending_oauth_client
  end

  test "login_methods_for_pending_oauth_client returns [] when client_id does not match an app" do
    @controller.session[:user_return_to] = "http://example.com/oauth/authorize?client_id=nonexistent"
    assert_equal [], login_methods_for_pending_oauth_client
  end

  test "login_methods_for_pending_oauth_client returns [] for invalid URI in return_to" do
    @controller.session[:user_return_to] = "not-a-valid-uri://"
    assert_equal [], login_methods_for_pending_oauth_client
  end

  # --- mailbox_available? ---

  test "mailbox_available? returns true when delivery method is test" do
    assert mailbox_available?, "delivery_method should be :test in test env"
  end

  # --- app_url ---

  def app_double(redirect_uri)
    Struct.new(:redirect_uri).new(redirect_uri)
  end

  test "app_url returns nil when redirect_uri is blank" do
    assert_nil app_url(app_double(nil))
  end

  test "app_url returns base URL from redirect_uri" do
    assert_equal "https://example.com", app_url(app_double("https://example.com/oauth/callback"))
  end

  test "app_url includes port when not 80 or 443" do
    assert_equal "https://example.com:3000", app_url(app_double("https://example.com:3000/callback"))
  end

  test "app_url uses first URI when redirect_uri has multiple" do
    assert_equal "https://a.com", app_url(app_double("https://a.com/cb https://b.com/cb"))
  end

  test "app_url returns nil for invalid URI" do
    assert_nil app_url(app_double("not-a-uri"))
  end

  def teardown
    ENV.delete("DEFAULT_LOGIN_METHODS")
    ENV.delete("GOOGLE_CLIENT_ID")
    ENV.delete("GOOGLE_CLIENT_SECRET")
    ENV.delete("GITHUB_CLIENT_ID")
    ENV.delete("GITHUB_CLIENT_SECRET")
    clear_signalwire_env
  end

  def clear_login_methods_env
    ENV.delete("DEFAULT_LOGIN_METHODS")
    clear_signalwire_env
  end

  def clear_signalwire_env
    ENV.delete("SIGNALWIRE_PROJECT_ID")
    ENV.delete("SIGNALWIRE_API_TOKEN")
    ENV.delete("SIGNALWIRE_SPACE_URL")
    ENV.delete("SIGNALWIRE_FROM_NUMBER")
  end
end
