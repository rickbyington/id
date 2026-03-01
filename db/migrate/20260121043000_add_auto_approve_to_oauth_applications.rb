# frozen_string_literal: true

class AddAutoApproveToOauthApplications < ActiveRecord::Migration[8.1]
  def change
    add_column :oauth_applications, :auto_approve, :boolean, default: false, null: false
  end
end
