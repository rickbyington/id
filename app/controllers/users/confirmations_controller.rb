# frozen_string_literal: true

class Users::ConfirmationsController < Devise::ConfirmationsController
  # Sign the user in automatically after they click the confirmation link (magic-link style).
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    yield resource if block_given?

    if resource.errors.empty?
      set_flash_message!(:notice, :confirmed)
      sign_in(resource_name, resource)
      respond_with_navigational(resource) { redirect_to after_confirmation_path_for(resource_name, resource) }
    else
      # If the email is already confirmed, send the user to sign-in instead of
      # showing the confirmation form with an error.
      if resource.errors.added?(:email, :already_confirmed)
        set_flash_message!(:notice, :already_confirmed)
        redirect_to new_session_path(resource_name)
      else
        respond_with_navigational(resource.errors, status: :unprocessable_entity) { render :new }
      end
    end
  end

  protected

  def after_confirmation_path_for(_resource_name, _resource)
    root_path
  end
end
