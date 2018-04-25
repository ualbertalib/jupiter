require_relative 'boot'

# not requiring rails/all to avoid loading ActionCable, at the moment
require 'rails'
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
require 'sprockets/railtie'
require 'rails/test_unit/railtie'

require 'active_storage'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, :staging, or :production.
Bundler.require(*Rails.groups)

module Jupiter
  class Application < Rails::Application

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set ActiveJob adapter
    config.active_job.queue_adapter = :sidekiq

    # Run skylight in UAT for performance metric monitoring pre-launch
    config.skylight.environments += ['uat']

    # Finding jupiter_core code before the ApplicationController loads
    config.eager_load_paths.prepend("#{config.root}/app/models/jupiter_core")

    config.redis_key_prefix = "jupiter.#{Rails.env}."

    # TODO: Remove after updating to Rails 5.2, as these are all rails 5.2 defaults
    # Rails 5.2 adds the last 3 headers by default, and specificly we want the referrer policy header
    # http://guides.rubyonrails.org/security.html#default-headers
    # TODO: Move to Rails 5.2 new DSL for Content Security Policy:
    # http://guides.rubyonrails.org/security.html#content-security-policy
    # TODO: Also, I am allowing unsafe-inline for script-src which kinda defats the purpose of CSP,
    # but we need a way to calculate nounces/hashes/etc
    # another improvement is for a better way to inject matomo_url into here instead of hardcoding
    config.action_dispatch.default_headers = {
      'X-Frame-Options' => 'SAMEORIGIN',
      'X-XSS-Protection' => '1; mode=block',
      'X-Content-Type-Options' => 'nosniff',
      'X-Download-Options' => 'noopen',
      'X-Permitted-Cross-Domain-Policies' => 'none',
      'Referrer-Policy' => 'strict-origin-when-cross-origin',
      'Content-Security-Policy' =>
        "default-src 'self'; " \
        "font-src 'self'; " \
        "img-src 'self' data: analytics.library.ualberta.ca www.google-analytics.com; " \
        "object-src 'none'; " \
        "script-src 'self' 'unsafe-inline' analytics.library.ualberta.ca www.google-analytics.com www.googletagmanager.com; " \
        "style-src 'self'; "
    }

  end
end
