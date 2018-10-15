Sidekiq.configure_server do |config|
  config.redis = { url: Rails.application.secrets.redis_url }

  schedule_file = 'config/schedule.yml'
  if File.exist?(schedule_file) && Rails.application.secrets.run_scheduled_jobs
    Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file) 
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: Rails.application.secrets.redis_url }
end
