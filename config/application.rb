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
require 'sprockets/railtie'
require 'rails/test_unit/railtie'

require_relative '../lib/jupiter/version'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, :staging, or :production.
Bundler.require(*Rails.groups)

module Jupiter
  class Application < Rails::Application

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # TODO: Remove soon once we tackle zeitwerk upgrade
    config.autoloader = :classic

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Set ActiveJob adapter
    config.active_job.queue_adapter = :sidekiq

    # Run skylight in UAT for performance metric monitoring pre-launch
    config.skylight.environments += ['uat']

    # Finding jupiter_core code before the ApplicationController loads
    config.eager_load_paths.prepend("#{config.root}/app/models/jupiter_core")

    config.redis_key_prefix = "jupiter.#{Rails.env}."

  end
end
