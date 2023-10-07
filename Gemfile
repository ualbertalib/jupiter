source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '>= 3.1.4', '< 3.2'

# Core Rails stuff
gem 'image_processing' # for ActiveStorage Variants
gem 'puma', '~> 6.4'
gem 'rails', '~> 6.1.7'

# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem 'webpacker', '~> 5.4'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.4', require: false

# View stuff
gem 'active_link_to'
gem 'simple_form'

# RDF stuff
gem 'acts_as_rdfable', github: 'ualbertalib/acts_as_rdfable', tag: '0.4.0'
gem 'rdf', '~> 3.3.1'
gem 'rdf-n3', '~> 3.3.0'
gem 'rdf-vocab', '~> 3.3.0' # this gem changed predicate names without warning, be cautious and test with migrations

# Database stuff
gem 'connection_pool'
gem 'pg', '~> 1.5.4'
gem 'redis', '~> 4.8'
gem 'rsolr'
gem 'strong_migrations', '~> 1.6.3'

# Authentication
gem 'bcrypt', '>= 3.1.13'
gem 'omniauth', '~> 2.1'
gem 'omniauth-rails_csrf_protection', '~> 1.0'
gem 'omniauth-saml', '~> 2.1'

# Authorization
gem 'pundit', '2.3.1'

# Background tasks
gem 'sidekiq', '~> 7.1'
gem 'sidekiq-cron', '~> 1.10'
gem 'sidekiq-unique-jobs', '~> 8.0'

# Misc Utilities
gem 'aasm' # state-machine management
gem 'addressable', '~> 2.8.5' # Replacement for the standard URI implementation
gem 'datacite-client', github: 'ualbertalib/datacite-client', tag: 'v0.1.0', require: 'datacite'
gem 'differ' # Used to diff two strings
gem 'draper'
gem 'edtf', '~> 3.1' # parsing Extended Date/Time Format
gem 'flipper', '~> 1.0.0' # Feature flags for Ruby
gem 'flipper-active_record', '~> 1.0.0' # Store feature flags in ActiveRecord
gem 'flipper-ui', '~> 1.0.0' # UI for feature flags
gem 'jbuilder' # generate JSON objects
gem 'kaminari' # Pagination
gem 'paper_trail', '~> 15.0.0' # Track object changes
gem 'ransack', '4.0.0' # ActiveRecord search/filter
gem 'redcarpet', '~> 3.6', require: ['redcarpet', 'redcarpet/render_strip'] # Markdown to (X)HTML parser
gem 'uuidtools'
gem 'voight_kampff', '~> 2.0', require: 'voight_kampff/rails' # bot detection
gem 'wicked' # Multi-step wizard

# resolve production errors in minutes
gem 'rollbar'

# Google Drive
gem 'google-api-client',
    require: ['google/api_client/client_secrets', 'google/apis/drive_v3', 'google/apis/sheets_v4', 'signet']

# OAI-PMH
gem 'builder_deferred_tagging', github: 'ualbertalib/builder_deferred_tagging', tag: 'v0.01'
gem 'oaisys', github: 'ualbertalib/oaisys', tag: 'v1.0.3'

# Seeds
group :development, :test, :uat do
  gem 'faker', require: false
end

group :development, :test do
  gem 'sdoc', require: false

  gem 'capybara', '>= 3.26', '< 4.0'
  gem 'nokogiri'
  gem 'selenium-webdriver', require: false

  gem 'erb_lint', '>= 0.0.35', require: false

  gem 'pry'
  gem 'pry-byebug'
  gem 'pry-rails'

  gem 'rubocop', '~> 1.56.4', require: false
  gem 'rubocop-minitest', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
end

group :development do
  gem 'better_errors', '>= 2.3.0'
  gem 'binding_of_caller'
  gem 'brakeman'
  gem 'listen'

  gem 'web-console', '>= 4.1.0'
end

group :test do
  gem 'danger', '~> 9.3', require: false # Pull Request etiquette enforcement
  gem 'simplecov'
  # Faker added 0.5 seconds to the test suite per call. Haikunator seems much faster for faking strings
  gem 'haikunator'
  gem 'shoulda-matchers', '~> 5.3'

  gem 'json-schema', '~> 4.1.1'
  gem 'launchy'
  gem 'minitest-retry', require: false
  gem 'rdf-isomorphic', '~> 3.3.0'
  gem 'vcr', '5.0', require: false
  gem 'webmock', require: false
end

group :staging, :production do
  gem 'clamby'
end
