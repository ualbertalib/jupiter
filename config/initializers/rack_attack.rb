class Rack::Attack

  class Request < ::Rack::Request

    class << self

      attr_accessor :allowed_ips

    end

    def allowed_ip?
      Request.allowed_ips[ip]
    end

  end

  # Using hash table to store allowed ips because it was found to be more efficient in benchmarking
  # https://github.com/ualbertalib/jupiter/issues/1247
  allowed_ips_array = Rails.application.secrets.rack_attack_safelisted_ips.split(',')
  Request.allowed_ips = allowed_ips_array.each_with_object({}) { |k, h| h[k] = true }
  safelist('allow safelisted ips', &:allowed_ip?)

  throttle('req/ip', limit: 60, period: 1.minute) do |req|
    req.ip if ['/search', '/', '/auth/saml'].include?(req.path)
  end

end

# Log blocked events
ActiveSupport::Notifications.subscribe('rack.attack') do |_, _, _, _, payload|
  req = payload[:request]
  if req.env['rack.attack.match_type'] == :throttle
    Rails.logger.info "[Rack::Attack][Blocked] ip: \"#{req.ip}\", path: \"#{req.path}\""
    Rollbar.info("[Rack::Attack][Blocked] ip: \"#{req.ip}\", path: \"#{req.path}\"")
  end
end
