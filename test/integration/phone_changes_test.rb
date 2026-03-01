# frozen_string_literal: true

require "test_helper"

class PhoneChangesTest < ActionDispatch::IntegrationTest
  def set_signalwire_env
    ENV["SIGNALWIRE_PROJECT_ID"]   = "pid"
    ENV["SIGNALWIRE_API_TOKEN"]    = "tok"
    ENV["SIGNALWIRE_SPACE_URL"]    = "space.signalwire.com"
    ENV["SIGNALWIRE_FROM_NUMBER"]  = "+15551234567"
  end

  def clear_signalwire_env
    ENV.delete("SIGNALWIRE_PROJECT_ID")
    ENV.delete("SIGNALWIRE_API_TOKEN")
    ENV.delete("SIGNALWIRE_SPACE_URL")
    ENV.delete("SIGNALWIRE_FROM_NUMBER")
  end

  setup do
    set_signalwire_env
  end

  teardown do
    clear_signalwire_env
  end

  test "GET new when not signed in redirects to sign in" do
    get new_user_phone_change_path
    assert_redirected_to new_user_session_path
  end

  test "GET new when signed in returns form" do
    user = User.create!(email: "u@x.com", password: "password123", password_confirmation: "password123")
    user.confirm
    sign_in user
    get new_user_phone_change_path
    assert_response :ok
  end

  test "POST create with same number redirects with notice" do
    user = User.create!(phone_number: "+15556666666", email: "u@x.com", password: "password123", password_confirmation: "password123")
    user.confirm
    sign_in user
    post user_phone_change_path, params: { phone: "+15556666666" }
    assert_redirected_to edit_user_registration_path
    follow_redirect!
    assert response.body.include?("already your current") || response.body.include?("already")
  end

  test "POST create with number in use by another account re-renders new" do
    User.create!(phone_number: "+15557777777", email: "", password: "password123", password_confirmation: "password123")
    user = User.create!(email: "other@x.com", password: "password123", password_confirmation: "password123")
    user.confirm
    sign_in user
    post user_phone_change_path, params: { phone: "+15557777777" }
    assert_response :unprocessable_entity
    assert response.body.include?("already in use") || response.body.include?("another account")
  end
end
