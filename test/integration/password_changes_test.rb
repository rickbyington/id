# frozen_string_literal: true

require "test_helper"

class PasswordChangesTest < ActionDispatch::IntegrationTest
  test "GET edit when signed in with password shows form" do
    user = User.create!(email: "pw@example.com", password: "password123", password_confirmation: "password123")
    user.confirm
    sign_in user
    get edit_user_password_change_path
    assert_response :ok
  end

  test "GET edit when signed in without password (phone-only) redirects with alert" do
    user = User.create!(phone_number: "+15551234567", email: "", password: "password123", password_confirmation: "password123")
    user.skip_confirmation!
    user.update_columns(encrypted_password: "")
    sign_in user
    get edit_user_password_change_path
    assert_redirected_to edit_user_registration_path
    follow_redirect!
    assert response.body.include?("no password") || response.body.include?("phone")
  end

  test "PUT update with valid current password updates password" do
    user = User.create!(email: "pw@example.com", password: "oldpass123", password_confirmation: "oldpass123")
    user.confirm
    sign_in user
    put user_password_change_path, params: {
      user: { current_password: "oldpass123", password: "newpass123", password_confirmation: "newpass123" }
    }
    assert_redirected_to edit_user_registration_path
    follow_redirect!
    assert response.body.include?("password has been changed") || response.body.include?("changed")
  end

  test "PUT update with wrong current password re-renders edit" do
    user = User.create!(email: "pw@example.com", password: "oldpass123", password_confirmation: "oldpass123")
    user.confirm
    sign_in user
    put user_password_change_path, params: {
      user: { current_password: "wrong", password: "newpass123", password_confirmation: "newpass123" }
    }
    assert_response :unprocessable_entity
  end

  test "GET edit when not signed in redirects to sign in" do
    get edit_user_password_change_path
    assert_redirected_to new_user_session_path
  end
end
