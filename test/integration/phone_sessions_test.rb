# frozen_string_literal: true

require "test_helper"

class PhoneSessionsTest < ActionDispatch::IntegrationTest
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

  test "GET new_phone_session when not signed in returns form" do
    get new_phone_session_path
    assert_response :ok
    assert response.body.include?("phone") || response.body.include?("Phone")
  end

  test "GET new_phone_session when signed in redirects to root" do
    user = User.create!(email: "u@x.com", password: "password123", password_confirmation: "password123")
    user.confirm
    sign_in user
    get new_phone_session_path
    assert_redirected_to root_path
  end

  test "POST create with invalid phone re-renders new with alert" do
    post phone_session_path, params: { phone: "invalid" }
    assert_response :unprocessable_entity
    assert response.body.include?("valid phone") || response.body.include?("phone")
  end

  test "POST create with valid unregistered phone redirects to verify (paranoid)" do
    post phone_session_path, params: { phone: "+15559999999" }
    assert_redirected_to verify_phone_session_path
  end

  test "POST create with valid registered confirmed phone sends OTP and redirects to verify" do
    user = User.create!(phone_number: "+15551111111", email: "", password: "password123", password_confirmation: "password123")
    user.skip_confirmation!
    user.update!(phone_confirmed_at: Time.current)
    post phone_session_path, params: { phone: "+15551111111" }
    assert_redirected_to verify_phone_session_path
    assert user.phone_otp_codes.for_purpose("sign_in").exists?
  end

  test "GET verify without phone in session redirects to new" do
    get verify_phone_session_path
    assert_redirected_to new_phone_session_path
  end

  test "POST confirm with valid code signs in and redirects" do
    user = User.create!(phone_number: "+15552222222", email: "", password: "password123", password_confirmation: "password123")
    user.skip_confirmation!
    user.update!(phone_confirmed_at: Time.current)
    # Capture the OTP code sent by POST create so we can submit it in confirm (no Minitest stub needed)
    captured_code = nil
    original_send_otp = SmsService.method(:send_otp)
    SmsService.define_singleton_method(:send_otp) do |to:, code:, purpose:|
      captured_code = code
      true
    end
    begin
      post phone_session_path, params: { phone: "+15552222222" }
      assert_redirected_to verify_phone_session_path
      post confirm_phone_session_path, params: { code: captured_code }
      assert_redirected_to root_path
      assert session["warden.user.user.key"].present?
    ensure
      SmsService.define_singleton_method(:send_otp, original_send_otp)
    end
  end
end
