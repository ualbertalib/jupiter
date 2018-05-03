require_relative 'boot'

# not requiring rails/all to avoid loading ActionCable, at the moment
require 'rails'
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'active_storage/engine'
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

  end
end
