module ApplicationHelper
  # Whether Google OAuth is configured (GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET in ENV).
  def omniauth_google_configured?
    ENV["GOOGLE_CLIENT_ID"].present? && ENV["GOOGLE_CLIENT_SECRET"].present?
  end

  # Whether GitHub OAuth is configured (GITHUB_CLIENT_ID, GITHUB_CLIENT_SECRET in ENV).
  def omniauth_github_configured?
    ENV["GITHUB_CLIENT_ID"].present? && ENV["GITHUB_CLIENT_SECRET"].present?
  end

  # Whether SignalWire SMS is configured (all four required ENV vars present).
  def signalwire_configured?
    ENV["SIGNALWIRE_PROJECT_ID"].present? &&
      ENV["SIGNALWIRE_API_TOKEN"].present? &&
      ENV["SIGNALWIRE_SPACE_URL"].present? &&
      ENV["SIGNALWIRE_FROM_NUMBER"].present?
  end

  # Whether the test mailbox page is available (no SMTP configured).
  def mailbox_available?
    ActionMailer::Base.delivery_method == :test
  end

  # Base URL of an OAuth application (from redirect_uri). Used to link to the app from the profile.
  def app_url(application)
    return nil if application.redirect_uri.blank?

    uri = URI.parse(application.redirect_uri.to_s.strip.split(/\s+/).first)
    return nil if uri.scheme.blank? || uri.host.blank?

    base = "#{uri.scheme}://#{uri.host}"
    base += ":#{uri.port}" if uri.port && ![ 80, 443 ].include?(uri.port)
    base
  rescue URI::InvalidURIError
    nil
  end

  # Default login methods when there is no OAuth client (direct visit to sign-in).
  # Set DEFAULT_LOGIN_METHODS to a comma-separated list, e.g. "email,phone,google,github".
  # If not set or blank, defaults to email + phone (when SignalWire is configured) or email only.
  def default_login_methods
    raw = ENV["DEFAULT_LOGIN_METHODS"].to_s.strip
    if raw.blank?
      return signalwire_configured? ? %w[ email phone ] : %w[ email ]
    end

    raw.split(",").map(&:strip).reject(&:blank?).presence || %w[ email ]
  end

  # Login methods allowed for the OAuth client that sent the user here (from stored return URL).
  # Used on the sign-in page to show only the login methods the client allows.
  def login_methods_for_pending_oauth_client
    stored = session[:user_return_to].to_s
    return [] unless stored.include?("/oauth/authorize")

    path_query = stored.start_with?("http") ? stored : "http://example.com#{stored}"
    uri = URI.parse(path_query)
    return [] unless uri.query.present?

    client_id = Rack::Utils.parse_query(uri.query)["client_id"]
    return [] if client_id.blank?

    app = Doorkeeper::Application.find_by(uid: client_id)
    return [] unless app&.respond_to?(:login_methods) && app.login_methods.present?

    app.login_methods.to_s.split(",").map(&:strip)
  rescue URI::InvalidURIError
    []
  end
end
