# frozen_string_literal: true

class User < ApplicationRecord
  # :validatable removed — we write custom validations to support phone-only users
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :confirmable

  has_many :user_permissions, dependent: :destroy
  has_many :permissions, through: :user_permissions
  has_many :login_activities, as: :user
  has_many :phone_otp_codes, dependent: :destroy

  # ── Validations ────────────────────────────────────────────────────────────

  validates :email,
            format: { with: Devise.email_regexp },
            uniqueness: { case_sensitive: false },
            allow_blank: true

  validates :phone_number,
            format: { with: /\A\+[1-9]\d{7,14}\z/, message: "must be in E.164 format (+15551234567)" },
            uniqueness: true,
            allow_blank: true

  validate :email_or_phone_present
  validates :password, presence: true, confirmation: true, length: { within: Devise.password_length }, if: :password_required?

  before_validation :normalize_phone_number

  # ── Helpers ─────────────────────────────────────────────────────────────────

  def email_user?
    email.present?
  end

  def phone_user?
    phone_number.present?
  end

  def phone_confirmed?
    phone_confirmed_at.present?
  end

  # Used by Devise :confirmable — skip email confirmation for phone-only users.
  def skip_confirmation_notification?
    email.blank?
  end

  # Devise :confirmable calls this to decide whether to send a confirmation email.
  # Phone-only users are confirmed via SMS OTP instead.
  def send_confirmation_instructions
    return if email.blank?

    super
  end

  # Allow phone-only users to sign in without email confirmation.
  def confirmation_required?
    email.present? && !confirmed?
  end

  # ── Permissions ─────────────────────────────────────────────────────────────

  def has_permission?(name, value = nil)
    rel = permissions.where(name: name)
    rel = rel.where(value: value) if value.present?
    rel.exists?
  end

  def permission_value(name)
    permissions.find_by(name: name)&.value
  end

  private

  def email_or_phone_present
    if email.blank? && phone_number.blank?
      errors.add(:base, "Email or phone number is required")
    end
  end

  def password_required?
    # Password is required for email users who don't already have one set
    email.present? && (new_record? || password.present?)
  end

  def normalize_phone_number
    value = self[:phone_number]
    return if value.blank?

    # Strip spaces, dashes, parens — keep leading +
    normalized = value.to_s.gsub(/[\s\-().]/, "")
    normalized = "+#{normalized}" unless normalized.start_with?("+")
    self.phone_number = normalized
  end
end
