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
    config.load_defaults 6.1

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Set ActiveJob adapter
    config.active_job.queue_adapter = :sidekiq

    # Run skylight in Staging for performance metric monitoring pre-launch
    config.skylight.environments << 'staging'

    config.redis_key_prefix = "jupiter.#{Rails.env}."

    config.action_dispatch.tld_length = Rails.application.secrets.tld_length.to_i

    # Set Redcarpet markdown options and extensions
    config.markdown_rendering_extensions = {
      lax_spacing: true,
      strikethrough: true,
      fenced_code_blocks: true,
      tables: true,
      autolink: true
    }
    config.markdown_rendering_options = {
      filter_html: true,
      no_images: true,
      no_styles: true,
      hard_wrap: true,
      link_attributes: { rel: 'noopener noreferrer', target: '_blank' }
    }

  end
end
