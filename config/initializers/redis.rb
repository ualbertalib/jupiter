module Jupiter
  module Redis
    def self.current
      @redis ||= ConnectionPool::Wrapper.new do
        ::Redis.new(url: Rails.application.secrets.redis_url)
      end
    end
  end
end
