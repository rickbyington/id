# frozen_string_literal: true

# Strip id_token and scope from token response for client_credentials (no resource owner).
module DoorkeeperOmitIdTokenForClientCredentials
  def body
    result = super
    return result unless result.is_a?(Hash) && token_without_owner?

    result = result.dup
    result.delete("id_token")
    result.delete(:id_token)
    result.delete("scope")
    result.delete(:scope)
    result
  end

  private

  def token_without_owner?
    return false unless defined?(@token) && @token

    @token.respond_to?(:resource_owner_id) && @token.resource_owner_id.nil?
  end
end
