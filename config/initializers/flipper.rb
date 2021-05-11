# Flipper group for admin
Flipper.register(:staff) do |actor|
  actor.respond_to?(:admin?) && actor.admin?
end

Flipper::UI.configure do |config|
  # When no feature flags, turn off random video
  config.fun = false
end
