source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '>= 3.1.4', '< 3.2'

# Core Rails stuff
gem 'image_processing' # for ActiveStorage Variants
gem 'puma', '~> 6.6'
gem 'rails', '~> 7.1.3'

# Assets
gem 'cssbundling-rails'
gem 'jsbundling-rails'
gem 'sprockets-rails'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# View stuff
gem 'active_link_to'
gem 'simple_form'

# RDF stuff
gem 'acts_as_rdfable', github: 'ualbertalib/acts_as_rdfable', tag: 'v0.5.0'
gem 'rdf', '~> 3.3.2'
gem 'rdf-n3', '~> 3.3.0'
gem 'rdf-vocab', '~> 3.3.2' # this gem changed predicate names without warning, be cautious and test with migrations

# Database stuff
gem 'connection_pool'
gem 'pg', '~> 1.5.9'
gem 'redis', '~> 4.8'
gem 'rsolr'
gem 'strong_migrations', '~> 2.2.0'

# Authentication
gem 'bcrypt', '>= 3.1.13'
gem 'omniauth', '~> 2.1'
gem 'omniauth-rails_csrf_protection', '~> 1.0'
gem 'omniauth-saml', '~> 2.2'

# Authorization
gem 'pundit', '2.5.0'

# Background tasks
gem 'sidekiq', '~> 7.3'
gem 'sidekiq-cron', '~> 2.1'
gem 'sidekiq-unique-jobs', '~> 8.0'

# Misc Utilities
gem 'aasm' # state-machine management
gem 'addressable', '~> 2.8.7' # Replacement for the standard URI implementation
gem 'datacite-client', github: 'ualbertalib/datacite-client', tag: 'v0.1.0', require: 'datacite'
gem 'differ' # Used to diff two strings
gem 'draper'
gem 'edtf', '~> 3.2' # parsing Extended Date/Time Format
gem 'flipper', '~> 1.3.4' # Feature flags for Ruby
gem 'flipper-active_record', '~> 1.3.4' # Store feature flags in ActiveRecord
gem 'flipper-ui', '~> 1.3.4' # UI for feature flags
gem 'jbuilder' # generate JSON objects
gem 'kaminari' # Pagination
gem 'paper_trail', '~> 16.0.0' # Track object changes
gem 'ransack', '4.3.0' # ActiveRecord search/filter
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

  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: [:mri, :mingw, :x64_mingw]

  gem 'rubocop', '~> 1.73.2', require: false
  gem 'rubocop-minitest', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
end

group :development do
  gem 'better_errors', '>= 2.3.0'
  gem 'binding_of_caller'
  gem 'brakeman'
  gem 'web-console', '>= 4.1.0'
end

group :test do
  gem 'danger', '~> 9.5', require: false # Pull Request etiquette enforcement
  gem 'simplecov'
  # Faker added 0.5 seconds to the test suite per call. Haikunator seems much faster for faking strings
  gem 'haikunator'
  gem 'shoulda-matchers', '~> 6.4'

  gem 'json-schema', '~> 5.1.1'
  gem 'launchy'
  gem 'minitest-retry', require: false
  gem 'rdf-isomorphic', '~> 3.3.0'
  gem 'vcr', '5.0', require: false
  gem 'webmock', require: false
end

group :staging, :production do
  gem 'clamby'
end
