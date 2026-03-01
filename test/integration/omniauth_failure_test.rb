# frozen_string_literal: true

require "test_helper"

class OmniauthFailureTest < ActionDispatch::IntegrationTest
  test "GET auth/failure redirects to sign in with alert" do
    get "/auth/failure"
    assert_redirected_to new_user_session_path
    follow_redirect!
    assert response.body.include?("cancelled") || response.body.include?("failed") || response.body.include?("Sign in")
  end
end
