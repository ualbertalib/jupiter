# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy


# TODO: Should be able to use nounces with UJS? But can't seem to get this to work. Needs more investigation.
# For time being, just using unsafe_inline for script_src :(
# unsafe_inline for style_src is for turbolinks as it adds styles to the page (progress bar)
Rails.application.config.content_security_policy do |policy|
  policy.default_src :self, :https
  policy.font_src    :self, :https, :data
  policy.img_src     :self, :https, :data,
                     'analytics.library.ualberta.ca',
                     'www.google-analytics.com'
  policy.object_src  :none
  policy.script_src  :self, :https, :unsafe_inline,
                     'analytics.library.ualberta.ca',
                     'www.google-analytics.com',
                     'www.googletagmanager.com'
  policy.style_src   :self, :https, :unsafe_inline

  # Specify URI for violation reports
  # policy.report_uri "/csp-violation-report-endpoint"
end


# If you are using UJS then enable automatic nonce generation
# Rails.application.config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
# Rails.application.config.content_security_policy_report_only = true
