require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_mailbox/engine'
require 'action_text/engine'
require 'action_view/railtie'
# require "action_cable/engine"
# require 'sprockets/railtie'
require 'rails/test_unit/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, :staging, or :production.
Bundler.require(*Rails.groups)

module Jupiter
  class Application < Rails::Application

    require_dependency 'lib/jupiter'
    require_dependency 'lib/jupiter/version'

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Set ActiveJob adapter
    config.active_job.queue_adapter = :sidekiq

    # Run skylight in UAT for performance metric monitoring pre-launch
    config.skylight.environments += ['uat']

    config.redis_key_prefix = "jupiter.#{Rails.env}."

    config.action_dispatch.tld_length = Rails.application.secrets.tld_length.to_i

  end
end
