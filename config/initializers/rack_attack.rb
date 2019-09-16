class Rack::Attack

  class Request < ::Rack::Request

    class << self

      attr_accessor :allowed_ips

    end

    def allowed_ip?
      Request.allowed_ips.include?(ip)
    end

  end

  Request.allowed_ips = Rails.application.secrets.rack_attack_safelisted_ips.split(',')
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
