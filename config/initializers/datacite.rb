Datacite.configure do |config|
  config.host = Rails.application.secrets.datacite_host
  config.username = Rails.application.secrets.datacite_username
  config.password = Rails.application.secrets.datacite_password
  config.prefix = Rails.application.secrets.datacite_prefix
end
