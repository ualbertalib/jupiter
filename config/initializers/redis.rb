Redis.current = Redis.new(url: Rails.application.secrets.redis_url)
