module Jupiter::Redis
  def self.current
    @current ||= ConnectionPool::Wrapper.new do
      ::Redis.new(url: Rails.application.secrets.redis_url)
    end
  end
end
