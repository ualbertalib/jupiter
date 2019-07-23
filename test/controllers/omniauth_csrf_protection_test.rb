require 'test_helper'

# Make sure that https://nvd.nist.gov/vuln/detail/CVE-2015-9284 is mitigated
class OmniauthTest < ActionDispatch::IntegrationTest

  test 'GET /auth/:provider' do
    assert_raise(ActionController::RoutingError) do
      get '/auth/saml'
    end
  end

  test 'POST /auth/:provider without CSRF token' do
    @allow_forgery_protection = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true

    assert_raise(ActionController::InvalidAuthenticityToken) do
      post '/auth/saml'
    end

    ActionController::Base.allow_forgery_protection = @allow_forgery_protection
  end

end
