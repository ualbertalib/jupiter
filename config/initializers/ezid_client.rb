Ezid::Client.configure do |config|
  config.host = Rails.application.secrets.ezid_host
  config.default_shoulder = Rails.application.secrets.ezid_default_shoulder
  config.user = Rails.application.secrets.ezid_user
  config.password = Rails.application.secrets.ezid_password
  config.identifier.defaults = { status: Ezid::Status::PUBLIC, profile: 'datacite' }
end
