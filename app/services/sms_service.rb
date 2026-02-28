# frozen_string_literal: true

# Sends SMS messages via SignalWire.
#
# Credentials (in Rails credentials or ENV):
#   signalwire:
#     project_id:  "your-project-id"
#     api_token:   "your-api-token"
#     space_url:   "yourspace.signalwire.com"
#     from_number: "+15551234567"
#
# ENV equivalents: SIGNALWIRE_PROJECT_ID, SIGNALWIRE_API_TOKEN,
#                  SIGNALWIRE_SPACE_URL, SIGNALWIRE_FROM_NUMBER
class SmsService
  class ConfigurationError < StandardError; end
  class DeliveryError < StandardError; end

  def self.send_otp(to:, code:, purpose: "verification")
    body = case purpose
           when "confirmation"
             "Your sign-up verification code is #{code}. It expires in 10 minutes."
           when "sign_in"
             "Your sign-in code is #{code}. It expires in 10 minutes."
           else
             "Your verification code is #{code}. It expires in 10 minutes."
           end

    new.send_message(to: to, body: body)
  end

  def send_message(to:, body:)
    if Rails.env.test?
      Rails.logger.info("[SmsService] TEST: to=#{to} body=#{body}")
      return true
    end

    if Rails.env.development? && ENV["SIGNALWIRE_PROJECT_ID"].blank? &&
        Rails.application.credentials.dig(:signalwire, :project_id).blank?
      Rails.logger.info("[SmsService] DEV (no credentials): to=#{to} body=#{body}")
      return true
    end

    client.messages.create(
      from: from_number,
      to:   to,
      body: body
    )
  rescue => e
    raise DeliveryError, "SMS delivery failed: #{e.message}"
  end

  private

  def client
    require "signalwire/sdk"
    Signalwire::REST::Client.new(
      project_id,
      api_token,
      signalwire_space_url: space_url
    )
  end

  def project_id
    fetch_credential(:project_id, "SIGNALWIRE_PROJECT_ID")
  end

  def api_token
    fetch_credential(:api_token, "SIGNALWIRE_API_TOKEN")
  end

  def space_url
    fetch_credential(:space_url, "SIGNALWIRE_SPACE_URL")
  end

  def from_number
    fetch_credential(:from_number, "SIGNALWIRE_FROM_NUMBER")
  end

  def fetch_credential(key, env_var)
    value = Rails.application.credentials.dig(:signalwire, key).presence ||
            ENV[env_var].presence
    raise ConfigurationError, "Missing SignalWire credential: #{key} (or #{env_var})" if value.blank?

    value
  end
end
