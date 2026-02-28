# frozen_string_literal: true

class Users::PasswordChangesController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_has_password

  def edit
  end

  def update
    if current_user.update_with_password(password_params)
      bypass_sign_in(current_user)
      redirect_to edit_user_registration_path, notice: "Your password has been changed."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def ensure_has_password
    if current_user.encrypted_password.blank?
      redirect_to edit_user_registration_path, alert: "You sign in with your phone number; there is no password to change."
    end
  end

  def password_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end
end
