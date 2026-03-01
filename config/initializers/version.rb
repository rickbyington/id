# frozen_string_literal: true

# Single source of version for the app. Update VERSION at project root when releasing.
# Tag releases as v0.1.0, v1.0.0, etc. and create GitHub Releases from those tags.
module Id
  VERSION = File.read(Rails.root.join("VERSION")).strip.freeze
end
