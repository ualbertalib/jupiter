module RedisClient
  class << self

    # Starting with version 4.6.0 Redis.current has been deprecated.
    # The author notes that typical multi-threaded applications will find a lot of locking around a shared redis client.
    # They recommend to define an own place to get a redis client, but also suggest to use a connection pool.
    # The accepted answer is therefore the simplest solution to achieve something comparable to Redis.current, but may
    # not perform optimal in multi-threaded environments.
    # https://stackoverflow.com/a/34673035
    def current
      @current ||= Redis.new(url: Rails.application.secrets.redis_url)
    end

  end
end
