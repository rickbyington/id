# frozen_string_literal: true

# Single RSA key pair for both OIDC ID tokens and JWT access tokens (RS256).
# Public key is exposed via OIDC discovery jwks_uri; resource servers use it to validate tokens.
# Set OIDC_PRIVATE_KEY in ENV (PEM string; newlines as \n). Generate: openssl genrsa 2048
raw = ENV["OIDC_PRIVATE_KEY"].to_s.presence
raw = raw.gsub("\\n", "\n") if raw
if raw.blank?
  if Rails.env.test? || Rails.env.development? || ENV["SECRET_KEY_BASE_DUMMY"].present?
    raw = OpenSSL::PKey::RSA.new(2048).to_pem
  else
    raise "Set OIDC_PRIVATE_KEY in ENV (PEM string)"
  end
end
OIDC_PRIVATE_KEY_PEM = raw.freeze
