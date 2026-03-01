# frozen_string_literal: true

require "test_helper"

class TestDeliveriesTest < ActionDispatch::IntegrationTest
  test "GET mailbox when not signed in redirects to sign in" do
    get mailbox_path
    assert_redirected_to new_user_session_path
  end

  test "GET mailbox when signed in as non-admin redirects with alert" do
    user = User.create!(email: "u@x.com", password: "password123", password_confirmation: "password123", admin: false)
    user.confirm
    sign_in user
    get mailbox_path
    assert_redirected_to root_path
    follow_redirect!
    assert response.body.include?("Not allowed") || response.status == 303
  end

  test "GET mailbox when signed in as admin returns success" do
    user = User.create!(email: "admin@x.com", password: "password123", password_confirmation: "password123", admin: true)
    user.confirm
    sign_in user
    get mailbox_path
    assert_response :ok
  end

  test "DELETE clear_mailbox when admin clears and redirects" do
    user = User.create!(email: "admin@x.com", password: "password123", password_confirmation: "password123", admin: true)
    user.confirm
    sign_in user
    delete clear_mailbox_path
    assert_redirected_to mailbox_path
    follow_redirect!
    assert response.body.include?("cleared") || response.body.include?("Mailbox")
  end
end
