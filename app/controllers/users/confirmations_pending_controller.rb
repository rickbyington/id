# frozen_string_literal: true

# Rendered after email sign-up when the account requires confirmation.
# Tells the user to check their email and click the link to confirm.
class Users::ConfirmationsPendingController < ApplicationController
  def show
    # Page is static; flash from registrations may already say "check your email"
  end
end
