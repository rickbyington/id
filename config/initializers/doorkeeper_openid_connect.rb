# frozen_string_literal: true

Doorkeeper::OpenidConnect.configure do
  # Issuer identifier - the base URL of your application
  # This should match your application's URL (e.g., https://yourdomain.com or http://localhost:3000)
  issuer do |resource_owner, application|
    Rails.application.routes.url_helpers.root_url(host: Rails.application.config.action_mailer.default_url_options[:host] || 'localhost',
                                                   port: Rails.application.config.action_mailer.default_url_options[:port],
                                                   protocol: Rails.env.production? ? 'https' : 'http')
  end

  # RSA private key for signing JWT tokens
  # Generate a key with: openssl genrsa -out config/oidc_private_key.pem 2048
  # Then read it: File.read(Rails.root.join('config', 'oidc_private_key.pem'))
  # Or store in credentials: Rails.application.credentials.oidc_private_key
  # Provide signing key as a PEM string (not a Proc) to avoid OpenSSL::PKey.read errors
  key_path = Rails.root.join('config', 'oidc_private_key.pem')
  signing_key_value = File.read(key_path) if key_path.exist?
  signing_key_value ||= Rails.application.credentials.dig(:oidc, :private_key)
  raise "Please provide an OIDC signing key (config/oidc_private_key.pem or credentials[:oidc][:private_key])" unless signing_key_value
  signing_key signing_key_value

  subject_types_supported [:public]

  # Get the User from the access token
  resource_owner_from_access_token do |access_token|
    User.find_by(id: access_token.resource_owner_id)
  end

  # Get the authentication time (when user last signed in; nil for client_credentials)
  auth_time_from_resource_owner do |resource_owner|
    next Time.current unless resource_owner

    if resource_owner.respond_to?(:current_sign_in_at) && resource_owner.current_sign_in_at
      resource_owner.current_sign_in_at
    else
      resource_owner.updated_at
    end
  end

  # Handle re-authentication (e.g., when max_age is specified)
  reauthenticate_resource_owner do |resource_owner, return_to|
    store_location_for(resource_owner, return_to) if return_to
    sign_out(resource_owner)
    redirect_to(new_user_session_url)
  end

  # Handle account selection (if you support multiple accounts per user)
  # For single account, this can be a no-op
  select_account_for_resource_owner do |resource_owner, return_to|
    # If you don't support account selection, you can leave this empty or redirect back
    # store_location_for(resource_owner, return_to) if return_to
    # redirect_to(account_select_url)
  end

  # Subject identifier - unique identifier for the user (nil for client_credentials grant)
   subject do |resource_owner, application|
    resource_owner ? resource_owner.id.to_s : "client_#{application.uid}"
  end

  # Protocol to use when generating URIs for the discovery endpoint,
  # for example if you also use HTTPS in development
  # protocol do
  #   :https
  # end

  # Expiration time on or after which the ID Token MUST NOT be accepted for processing. (default 120 seconds).
  # expiration 600

  # Example claims:
  # claims do
  #   normal_claim :_foo_ do |resource_owner|
  #     resource_owner.foo
  #   end
  claims do
    normal_claim :email, scope: :email, response: %i[id_token user_info] do |resource_owner|
      resource_owner.email
    end

    normal_claim :name, scope: :profile, response: %i[id_token user_info] do |resource_owner|
      [resource_owner.first_name, resource_owner.last_name].compact.join(" ").presence
    end

    normal_claim :given_name, scope: :profile, response: %i[id_token user_info] do |resource_owner|
      resource_owner.first_name
    end

    normal_claim :family_name, scope: :profile, response: %i[id_token user_info] do |resource_owner|
      resource_owner.last_name
    end

    normal_claim :permissions, response: %i[id_token user_info] do |resource_owner|
      resource_owner.permissions.map { |p| { name: p.name, value: p.value } }
    end
  end

  #   normal_claim :_bar_ do |resource_owner|
  #     resource_owner.bar
  #   end
  # end
end
