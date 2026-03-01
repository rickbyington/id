# frozen_string_literal: true

class CreatePhoneOtpCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :phone_otp_codes do |t|
      t.references :user, null: false, foreign_key: true
      t.string   :code_digest, null: false
      t.string   :purpose,     null: false  # "confirmation" | "sign_in"
      t.datetime :expires_at,  null: false
      t.datetime :used_at
      t.integer  :attempts,    null: false, default: 0

      t.timestamps
    end

    add_index :phone_otp_codes, [ :user_id, :purpose ]
    add_index :phone_otp_codes, :created_at
  end
end
