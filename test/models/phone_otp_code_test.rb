# frozen_string_literal: true

require "test_helper"

class PhoneOtpCodeTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(phone_number: "+15551234567", email: "", password: "password123", password_confirmation: "password123")
    @user.skip_confirmation!
  end

  test "generate_for creates a record and returns record and plain code" do
    record, code = PhoneOtpCode.generate_for(@user, purpose: "sign_in")
    assert record.persisted?
    assert_equal 6, code.length
    assert code.match?(/\A\d{6}\z/)
    assert_equal @user.id, record.user_id
    assert_equal "sign_in", record.purpose
    assert record.expires_at > Time.current
  end

  test "verify! returns true for correct code and marks used" do
    record, code = PhoneOtpCode.generate_for(@user, purpose: "sign_in")
    assert record.verify!(code)
    assert record.reload.used_at.present?
  end

  test "verify! returns false for wrong code and increments attempts" do
    record, _code = PhoneOtpCode.generate_for(@user, purpose: "sign_in")
    refute record.verify!("000000")
    assert_equal 1, record.reload.attempts
  end

  test "verify! returns false when already used" do
    record, code = PhoneOtpCode.generate_for(@user, purpose: "sign_in")
    record.verify!(code)
    refute record.verify!(code)
  end

  test "verify! returns false when expired" do
    record, code = PhoneOtpCode.generate_for(@user, purpose: "sign_in")
    record.update_column(:expires_at, 1.minute.ago)
    refute record.verify!(code)
  end

  test "verify! returns false when locked out" do
    record, code = PhoneOtpCode.generate_for(@user, purpose: "sign_in")
    record.update_columns(attempts: PhoneOtpCode::MAX_ATTEMPTS)
    refute record.verify!(code)
  end

  test "used? returns true when used_at set" do
    record, code = PhoneOtpCode.generate_for(@user, purpose: "sign_in")
    record.verify!(code)
    assert record.reload.used?
  end

  test "expired? returns true when expires_at in past" do
    record, _ = PhoneOtpCode.generate_for(@user, purpose: "sign_in")
    record.update_column(:expires_at, 1.minute.ago)
    assert record.expired?
  end

  test "locked_out? returns true when attempts >= MAX_ATTEMPTS" do
    record, _ = PhoneOtpCode.generate_for(@user, purpose: "sign_in")
    record.update_columns(attempts: PhoneOtpCode::MAX_ATTEMPTS)
    assert record.locked_out?
  end

  test "generate_for invalidates previous active codes for same user and purpose" do
    PhoneOtpCode.generate_for(@user, purpose: "sign_in")
    _, code2 = PhoneOtpCode.generate_for(@user, purpose: "sign_in")
    active = @user.phone_otp_codes.for_purpose("sign_in").active
    assert_equal 1, active.count
    assert active.last.verify!(code2)
  end
end
