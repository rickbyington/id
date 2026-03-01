# frozen_string_literal: true

require "test_helper"

class ConfirmationsPendingTest < ActionDispatch::IntegrationTest
  test "GET signup_check_email returns success" do
    get signup_check_email_path
    assert_response :ok
    assert response.body.include?("email") || response.body.include?("confirm")
  end
end
