require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Id
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Fail fast if SECRET_KEY_BASE is missing (avoids secure_compare errors from nil).
    # Skip during assets:precompile (Dockerfile sets SECRET_KEY_BASE_DUMMY=1).
    config.after_initialize do
      next if ENV["SECRET_KEY_BASE_DUMMY"].present?
      if Rails.application.secret_key_base.blank?
        raise "SECRET_KEY_BASE is not set. Set it in ENV (e.g. .env or .kamal/secrets)."
      end
    end
  end
end
