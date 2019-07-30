Rails.application.config.middleware.use OmniAuth::Builder do
  provider :saml,
           assertion_consumer_service_url: Rails.application.secrets.saml_assertion_consumer_service_url,
           idp_cert: Rails.application.secrets.saml_idp_cert,
           certificate: Rails.application.secrets.saml_certificate,
           private_key: Rails.application.secrets.saml_private_key,
           idp_sso_target_url: Rails.application.secrets.saml_idp_sso_target_url,
           issuer: Rails.application.secrets.saml_issuer,
           name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:transient',
           attribute_statements: {
             # TODO: How to get values as human readable instead of URNs?
             # Shibboleth had an attribute-map.xml for mapping this...must be a way or up to IdP?
             email: ['urn:oid:0.9.2342.19200300.100.1.3'], # mail
             name: ['urn:oid:2.16.840.1.113730.3.1.241'] # displayName
           }

  provider :developer if Rails.env.development? || Rails.env.uat?

  # By default in development mode, omniauth raises an exception when authentication fails
  # comment this line if you want to see the stacktrace from the actual provider when in `development`
  # Uncomment the line below to turn this behavior off
  on_failure { |env| SessionsController.action(:failure).call(env) }

  OmniAuth.config.allowed_request_methods = [:post]
  OmniAuth.config.logger = Rails.logger
end
