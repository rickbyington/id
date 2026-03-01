# frozen_string_literal: true

require "test_helper"

class AdminTest < ActionDispatch::IntegrationTest
  test "GET admin root when not signed in redirects to sign in" do
    get admin_root_path
    assert_redirected_to new_user_session_path
  end

  test "GET admin root when signed in as non-admin redirects" do
    user = User.create!(email: "u@x.com", password: "password123", password_confirmation: "password123", admin: false)
    user.confirm
    sign_in user
    get admin_root_path
    assert_response :see_other
    assert_redirected_to root_path
  end

  test "GET admin root when signed in as admin returns success" do
    user = User.create!(email: "admin@x.com", password: "password123", password_confirmation: "password123", admin: true)
    user.confirm
    sign_in user
    get admin_root_path
    assert_response :ok
  end

  test "GET admin users index when admin returns success" do
    user = User.create!(email: "admin@x.com", password: "password123", password_confirmation: "password123", admin: true)
    user.confirm
    sign_in user
    get admin_users_path
    assert_response :ok
  end
end
