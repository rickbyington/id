class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  # Redirect to sign-in with a notice when SignalWire SMS is not configured.
  # Used as a before_action in phone auth controllers.
  def require_signalwire
    unless helpers.signalwire_configured?
      redirect_to new_user_session_path, alert: "Phone sign-in is not available."
    end
  end
end
