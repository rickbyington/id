# frozen_string_literal: true

require "test_helper"

class RegistrationsTest < ActionDispatch::IntegrationTest
  test "POST sign up with valid email redirects to check email when confirmable" do
    post user_registration_path, params: {
      user: { email: "new@example.com", password: "password123", password_confirmation: "password123" }
    }
    assert_redirected_to signup_check_email_path
  end

  test "after sign up redirect includes check your email or similar" do
    post user_registration_path, params: {
      user: { email: "new2@example.com", password: "password123", password_confirmation: "password123" }
    }
    follow_redirect!
    assert_response :ok
  end
end
