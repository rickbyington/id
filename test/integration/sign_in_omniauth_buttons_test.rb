# frozen_string_literal: true

require "test_helper"

class SignInOmniAuthButtonsTest < ActionDispatch::IntegrationTest
  ENV_KEYS = %w[DEFAULT_LOGIN_METHODS GOOGLE_CLIENT_ID GOOGLE_CLIENT_SECRET GITHUB_CLIENT_ID GITHUB_CLIENT_SECRET].freeze

  def with_env(env_overrides)
    old = ENV_KEYS.to_h { |k| [ k, ENV[k] ] }
    env_overrides.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
    yield
  ensure
    old.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end

  test "when neither configured does not show Sign in with Google" do
    with_env("DEFAULT_LOGIN_METHODS" => nil, "GOOGLE_CLIENT_ID" => nil, "GOOGLE_CLIENT_SECRET" => nil, "GITHUB_CLIENT_ID" => nil, "GITHUB_CLIENT_SECRET" => nil) do
      get new_user_session_path
      assert_response :ok
      assert_not response.body.include?("Sign in with Google")
    end
  end

  test "when neither configured does not show Sign in with GitHub" do
    with_env("DEFAULT_LOGIN_METHODS" => nil, "GOOGLE_CLIENT_ID" => nil, "GOOGLE_CLIENT_SECRET" => nil, "GITHUB_CLIENT_ID" => nil, "GITHUB_CLIENT_SECRET" => nil) do
      get new_user_session_path
      assert_response :ok
      assert_not response.body.include?("Sign in with GitHub")
    end
  end

  test "when neither configured does not show social login links" do
    with_env("DEFAULT_LOGIN_METHODS" => nil, "GOOGLE_CLIENT_ID" => nil, "GOOGLE_CLIENT_SECRET" => nil, "GITHUB_CLIENT_ID" => nil, "GITHUB_CLIENT_SECRET" => nil) do
      get new_user_session_path
      assert_response :ok
      assert_not response.body.include?("/auth/google_oauth2")
      assert_not response.body.include?("/auth/github")
    end
  end

  test "when only Google configured shows Sign in with Google" do
    with_env("DEFAULT_LOGIN_METHODS" => "email,google", "GOOGLE_CLIENT_ID" => "id", "GOOGLE_CLIENT_SECRET" => "secret", "GITHUB_CLIENT_ID" => nil, "GITHUB_CLIENT_SECRET" => nil) do
      get new_user_session_path
      assert_response :ok
      assert response.body.include?("Sign in with Google")
    end
  end

  test "when only Google configured does not show Sign in with GitHub" do
    with_env("DEFAULT_LOGIN_METHODS" => "email,google", "GOOGLE_CLIENT_ID" => "id", "GOOGLE_CLIENT_SECRET" => "secret", "GITHUB_CLIENT_ID" => nil, "GITHUB_CLIENT_SECRET" => nil) do
      get new_user_session_path
      assert_response :ok
      assert_not response.body.include?("Sign in with GitHub")
    end
  end

  test "when only GitHub configured does not show Sign in with Google" do
    with_env("DEFAULT_LOGIN_METHODS" => "email,github", "GOOGLE_CLIENT_ID" => nil, "GOOGLE_CLIENT_SECRET" => nil, "GITHUB_CLIENT_ID" => "id", "GITHUB_CLIENT_SECRET" => "secret") do
      get new_user_session_path
      assert_response :ok
      assert_not response.body.include?("Sign in with Google")
    end
  end

  test "when only GitHub configured shows Sign in with GitHub" do
    with_env("DEFAULT_LOGIN_METHODS" => "email,github", "GOOGLE_CLIENT_ID" => nil, "GOOGLE_CLIENT_SECRET" => nil, "GITHUB_CLIENT_ID" => "id", "GITHUB_CLIENT_SECRET" => "secret") do
      get new_user_session_path
      assert_response :ok
      assert response.body.include?("Sign in with GitHub")
    end
  end

  test "when both configured shows Sign in with Google" do
    with_env("DEFAULT_LOGIN_METHODS" => "email,google,github", "GOOGLE_CLIENT_ID" => "id", "GOOGLE_CLIENT_SECRET" => "secret", "GITHUB_CLIENT_ID" => "id", "GITHUB_CLIENT_SECRET" => "secret") do
      get new_user_session_path
      assert_response :ok
      assert response.body.include?("Sign in with Google")
    end
  end

  test "when both configured shows Sign in with GitHub" do
    with_env("DEFAULT_LOGIN_METHODS" => "email,google,github", "GOOGLE_CLIENT_ID" => "id", "GOOGLE_CLIENT_SECRET" => "secret", "GITHUB_CLIENT_ID" => "id", "GITHUB_CLIENT_SECRET" => "secret") do
      get new_user_session_path
      assert_response :ok
      assert response.body.include?("Sign in with GitHub")
    end
  end
end
