# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  protected

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name)
  end

  def account_update_params
    params.require(:user).permit(:email, :password, :password_confirmation, :current_password, :first_name, :last_name)
  end

  # Phone-only users have no password; allow them to update without current_password.
  # Users with a password:
  # - can change name/email without current_password
  # - must use the dedicated Change password screen to update password
  def update_resource(resource, params)
    params.delete(:current_password)

    # No password set (phone-only or similar) → always allow update without password
    return resource.update_without_password(params) if resource.encrypted_password.blank?

    # With a password, handle password changes on the dedicated Change password screen.
    # Here we only update non-password attributes (e.g. name, email).
    params.delete(:password)
    params.delete(:password_confirmation)

    resource.update_without_password(params)
  end

  # After sign-up (when already confirmed, e.g. phone user) redirect to root.
  def after_sign_up_path_for(resource)
    root_path
  end

  # When sign-up requires email confirmation, send user to "check your email" page.
  def after_inactive_sign_up_path_for(resource)
    signup_check_email_path
  end
end
