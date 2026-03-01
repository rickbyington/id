# frozen_string_literal: true

require "test_helper"

class UsersSessionsTest < ActionDispatch::IntegrationTest
  def with_env(overrides = {})
    old = {}
    overrides.each_key { |k| old[k] = ENV[k] }
    overrides.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
    yield
  ensure
    old.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end

  test "GET signin when no OAuth context renders sign in page" do
    with_env("DEFAULT_LOGIN_METHODS" => nil) do
      get new_user_session_path
      assert_response :ok
      assert response.body.include?("Sign in")
    end
  end

  test "GET signin when OAuth client allows only Google redirects to Google OAuth" do
    app = create_oauth_application(
      name: "OAuth App",
      redirect_uri: "https://app.com/callback",
      login_methods: "google"
    )
    with_env("GOOGLE_CLIENT_ID" => "id", "GOOGLE_CLIENT_SECRET" => "secret", "GITHUB_CLIENT_ID" => nil, "GITHUB_CLIENT_SECRET" => nil) do
      get oauth_authorization_path(client_id: app.uid, redirect_uri: "https://app.com/callback", response_type: "code", scope: "openid")
      assert_response :redirect
      follow_redirect!
      assert_response :redirect
      assert response.location.include?("/auth/google_oauth2")
    end
  end

  test "GET signin when OAuth client allows only GitHub redirects to GitHub OAuth" do
    app = create_oauth_application(
      name: "OAuth App",
      redirect_uri: "https://app.com/callback",
      login_methods: "github"
    )
    with_env("GOOGLE_CLIENT_ID" => nil, "GOOGLE_CLIENT_SECRET" => nil, "GITHUB_CLIENT_ID" => "id", "GITHUB_CLIENT_SECRET" => "secret") do
      get oauth_authorization_path(client_id: app.uid, redirect_uri: "https://app.com/callback", response_type: "code", scope: "openid")
      assert_response :redirect
      follow_redirect!
      assert_response :redirect
      assert response.location.include?("/auth/github")
    end
  end

  test "GET signin when OAuth client allows email renders sign in page" do
    app = create_oauth_application(
      name: "OAuth App",
      redirect_uri: "https://app.com/callback",
      login_methods: "email,google"
    )
    with_env("GOOGLE_CLIENT_ID" => "id", "GOOGLE_CLIENT_SECRET" => "secret", "DEFAULT_LOGIN_METHODS" => nil) do
      get oauth_authorization_path(client_id: app.uid, redirect_uri: "https://app.com/callback", response_type: "code", scope: "openid")
      assert_response :redirect
      follow_redirect!
      assert_response :ok
      assert response.body.include?("Sign in")
    end
  end

  test "GET signin when OAuth client allows both Google and GitHub renders sign in page" do
    app = create_oauth_application(
      name: "OAuth App",
      redirect_uri: "https://app.com/callback",
      login_methods: "google,github"
    )
    with_env("GOOGLE_CLIENT_ID" => "id", "GOOGLE_CLIENT_SECRET" => "secret", "GITHUB_CLIENT_ID" => "id", "GITHUB_CLIENT_SECRET" => "secret", "DEFAULT_LOGIN_METHODS" => nil) do
      get oauth_authorization_path(client_id: app.uid, redirect_uri: "https://app.com/callback", response_type: "code", scope: "openid")
      assert_response :redirect
      follow_redirect!
      assert_response :ok
      assert response.body.include?("Sign in")
    end
  end
end
