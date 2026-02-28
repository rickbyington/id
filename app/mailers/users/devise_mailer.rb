# frozen_string_literal: true

# Custom Devise mailer that silently skips sending emails to phone-only users
# (users with no email address).
class Users::DeviseMailer < Devise::Mailer
  def confirmation_instructions(record, token, opts = {})
    return if record.email.blank?

    super
  end

  def reset_password_instructions(record, token, opts = {})
    return if record.email.blank?

    super
  end

  def email_changed(record, opts = {})
    return if record.email.blank?

    super
  end

  def password_change(record, opts = {})
    return if record.email.blank?

    super
  end
end
