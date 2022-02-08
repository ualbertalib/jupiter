module Cache
  class << self

    def redis
      @redis ||= Redis.new(url: Rails.application.secrets.redis_url)
    end

  end
end
