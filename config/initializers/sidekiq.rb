require 'yaml'
require 'erb'
secrets = YAML.load_file("config/secrets.yml")
redis_url = ERB.new(secrets["shared"]["redis_url"]).result(binding)
Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end
