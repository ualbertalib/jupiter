SIDEKIQ_HAS_STARTED_FILE = Rails.root.join('tmp/sidekiq_process_has_started').freeze

Sidekiq.configure_server do |config|
  config.redis = { url: Rails.application.secrets.redis_url }

  schedule_file = 'config/schedule.yml'
  Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file) if File.exist?(schedule_file)

  # We touch and destroy files in the Sidekiq lifecycle to provide a
  # signal to Kubernetes that we are ready to process jobs or not.
  #
  # Doing this gives us a better sense of when a process is actually
  # alive and healthy, rather than just beginning the boot process.
  config.on(:startup) do
    FileUtils.touch(SIDEKIQ_HAS_STARTED_FILE)
  end

  config.on(:shutdown) do
    FileUtils.rm_f(SIDEKIQ_HAS_STARTED_FILE)
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: Rails.application.secrets.redis_url }
end

require 'sidekiq/web'
Sidekiq::Web.app_url = '/admin'
