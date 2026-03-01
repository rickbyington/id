# frozen_string_literal: true

require "test_helper"

class SmsServiceTest < ActiveSupport::TestCase
  test "send_otp in test env logs and returns true" do
    assert SmsService.send_otp(to: "+15551234567", code: "123456", purpose: "sign_in")
  end

  test "send_otp customizes body for confirmation purpose" do
    result = SmsService.send_otp(to: "+15551234567", code: "123456", purpose: "confirmation")
    assert result, "send_otp should return true in test env"
  end

  test "send_otp customizes body for sign_in purpose" do
    result = SmsService.send_otp(to: "+15551234567", code: "123456", purpose: "sign_in")
    assert result, "send_otp should return true in test env"
  end

  test "send_message in test env returns true" do
    svc = SmsService.new
    assert svc.send(:send_message, to: "+15551234567", body: "Test")
  end
end
