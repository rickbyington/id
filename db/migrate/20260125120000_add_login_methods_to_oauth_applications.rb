# frozen_string_literal: true

class AddLoginMethodsToOauthApplications < ActiveRecord::Migration[8.1]
  def change
    add_column :oauth_applications, :login_methods, :string, default: "email", null: false
  end
end
