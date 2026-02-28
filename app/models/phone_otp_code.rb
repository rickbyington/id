# frozen_string_literal: true

require "bcrypt"

class PhoneOtpCode < ApplicationRecord
  belongs_to :user

  MAX_ATTEMPTS = 5
  OTP_EXPIRY   = 10.minutes

  scope :for_purpose, ->(p) { where(purpose: p) }
  scope :unexpired,   -> { where("expires_at > ?", Time.current) }
  scope :unused,      -> { where(used_at: nil) }
  scope :active,      -> { unexpired.unused }

  # Generate a new OTP for the given user and purpose.
  # Invalidates any previous active code for the same user+purpose.
  def self.generate_for(user, purpose:)
    where(user: user, purpose: purpose).active.update_all(used_at: Time.current)

    code = SecureRandom.random_number(10**6).to_s.rjust(6, "0")
    digest = BCrypt::Password.create(code)

    record = create!(
      user:        user,
      purpose:     purpose,
      code_digest: digest,
      expires_at:  OTP_EXPIRY.from_now
    )

    [ record, code ]
  end

  # Returns true if the submitted code matches and the record is still valid.
  # Increments attempts on failure; marks used on success.
  def verify!(submitted_code)
    return false if used?
    return false if expired?
    return false if locked_out?

    if BCrypt::Password.new(code_digest) == submitted_code
      update!(used_at: Time.current)
      true
    else
      increment!(:attempts)
      false
    end
  end

  def used?
    used_at.present?
  end

  def expired?
    expires_at <= Time.current
  end

  def locked_out?
    attempts >= MAX_ATTEMPTS
  end
end
