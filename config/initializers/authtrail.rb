# frozen_string_literal: true

# AuthTrail tracks Devise login activity in login_activities (success + failure).
# See https://github.com/ankane/authtrail
#
# Optional: exclude certain attempts (e.g. test users)
# AuthTrail.exclude_method = ->(data) { data[:identity] == "test@example.org" }
#
# Optional: add geocoding (add gem "geocoder", then AuthTrail.geocode = true)

# Define AuthTrail::LoginActivity after the app is initialized (ApplicationRecord exists).
# The gem expects this constant but doesn't ship a model; we provide it and require it here
# so it's available when the Warden callback runs on sign_in.
Rails.application.config.after_initialize do
  require Rails.root.join("app/models/authtrail/login_activity.rb").to_s
end
