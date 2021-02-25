Flipper.configure do |config|
  config.default do
    require 'flipper/adapters/active_record'
    adapter = Flipper::Adapters::ActiveRecord.new

    # pass adapter to handy DSL instance
    Flipper.new(adapter)
  end
end

# Flipper group for admin
Flipper.register(:staff) do |actor|
  actor.respond_to?(:admin?) && actor.admin?
end

Flipper::UI.configure do |config|
  # When no feature flags, turn off random video
  config.fun = false
end

require 'flipper/middleware/memoizer'
Rails.application.config.middleware.use Flipper::Middleware::Memoizer
