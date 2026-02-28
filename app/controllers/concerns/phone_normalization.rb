# frozen_string_literal: true

module PhoneNormalization
  extend ActiveSupport::Concern

  private

  def normalize_phone(raw)
    return "" if raw.blank?

    cleaned = raw.to_s.gsub(/[\s\-().]/, "")
    cleaned.start_with?("+") ? cleaned : "+#{cleaned}"
  end

  def valid_e164?(phone)
    phone.match?(/\A\+[1-9]\d{7,14}\z/)
  end
end

