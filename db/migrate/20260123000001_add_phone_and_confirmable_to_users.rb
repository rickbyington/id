# frozen_string_literal: true

class AddPhoneAndConfirmableToUsers < ActiveRecord::Migration[8.1]
  def change
    # Phone auth
    add_column :users, :phone_number, :string
    add_column :users, :phone_confirmed_at, :datetime

    # Devise :confirmable columns for email confirmation
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :unconfirmed_email, :string

    add_index :users, :phone_number, unique: true
    add_index :users, :confirmation_token, unique: true

    # Allow email-less (phone-only) users
    change_column_null :users, :email, true
    change_column_default :users, :email, nil

    # Allow password-less (phone-only) users
    change_column_null :users, :encrypted_password, true
    change_column_default :users, :encrypted_password, nil
  end
end
