# frozen_string_literal: true

require "test_helper"

class PhoneRegistrationsIntegrationTest < ActionDispatch::IntegrationTest
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

  test "GET new returns form" do
    get new_phone_registration_path
    assert_response :ok
  end

  test "POST create with invalid phone re-renders new" do
    post phone_registration_path, params: { phone: "x" }
    assert_response :unprocessable_entity
  end

  test "POST create with valid new phone creates user and redirects to verify" do
    post phone_registration_path, params: { phone: "+15553333333" }
    assert_redirected_to verify_phone_registration_path
    assert User.exists?(phone_number: "+15553333333")
  end

  test "GET verify without phone_signup_id redirects to new" do
    get verify_phone_registration_path
    assert_redirected_to new_phone_registration_path
  end

  test "POST confirm with valid code confirms phone and signs in" do
    post phone_registration_path, params: { phone: "+15554444444" }
    user = User.find_by!(phone_number: "+15554444444")
    record, code = PhoneOtpCode.generate_for(user, purpose: "confirmation")
    post confirm_phone_registration_path, params: { code: code }
    assert_redirected_to root_path
    assert user.reload.phone_confirmed_at.present?
  end

  test "GET resend without session redirects with alert" do
    get resend_phone_registration_path
    assert_redirected_to new_phone_registration_path
  end
end
