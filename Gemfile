source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Core Rails stuff
gem 'image_processing' # for ActiveStorage Variants
gem 'puma', '~> 5.2'
gem 'rails', '~> 6.0.3'

# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem 'webpacker', '~> 5.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.2', require: false

# View stuff
gem 'active_link_to'
gem 'simple_form'

# RDF stuff
gem 'acts_as_rdfable', github: 'ualbertalib/acts_as_rdfable', tag: 'v0.2.4'
gem 'rdf', '~> 3.1.13'
gem 'rdf-n3', '~> 3.1.2'
gem 'rdf-vocab', '~> 3.1.12'

# Database stuff
gem 'connection_pool'
gem 'pg', '~> 1.2.3'
gem 'redis', '~> 4.1'
gem 'rsolr'

# Authentication
gem 'bcrypt', '>= 3.1.13'
gem 'omniauth', '~> 2.0'
gem 'omniauth-rails_csrf_protection', '~> 1.0'
gem 'omniauth-saml', '~> 2.0'

# Authorization
gem 'pundit', '1.1.0'

# Background tasks
gem 'sidekiq', '~> 5.2'
gem 'sidekiq-unique-jobs', '~> 6.0'
gem 'sinatra', '~> 2.1.0' # used by sidekiq/web
# Sidekiq cron jobs
gem 'rufus-scheduler', '3.7.0' # https://github.com/ondrejbartas/sidekiq-cron/issues/199
gem 'sidekiq-cron'

# Misc Utilities
gem 'aasm' # state-machine management
gem 'addressable', '~> 2.7.0' # Replacement for the standard URI implementation
gem 'differ' # Used to diff two strings
gem 'draper'
gem 'edtf', '~> 3.0', '>= 3.0.6' # parsing Extended Date/Time Format
gem 'ezid-client', '~> 1.8.0'
gem 'flipper', '~> 0.20.4' # Feature flags for Ruby
gem 'flipper-active_record', '~> 0.20.4' # Store feature flags in ActiveRecord
gem 'flipper-ui', '~> 0.20.4' # UI for feature flags
gem 'jbuilder' # generate JSON objects
gem 'kaminari' # Pagination
gem 'paper_trail' # Track object changes
gem 'ransack', '= 2.4.1' # ActiveRecord search/filter
gem 'uuidtools'
gem 'voight_kampff' # bot detection
gem 'wicked' # Multi-step wizard

# Performance monitoring
gem 'skylight', '~> 4.3'
# resolve production errors in minutes
gem 'rollbar'

# OAI-PMH
gem 'builder_deferred_tagging', github: 'ualbertalib/builder_deferred_tagging', tag: 'v0.01'
gem 'oaisys', github: 'ualbertalib/oaisys', tag: 'v1.0.2'

# Seeds
group :development, :test, :uat do
  gem 'faker', require: false
end

group :development, :test do
  gem 'sdoc', require: false

  gem 'capybara', '>= 2.15', '< 4.0'
  gem 'nokogiri'
  gem 'selenium-webdriver', require: false

  gem 'erb_lint', '>= 0.0.35', require: false

  gem 'pry'
  gem 'pry-byebug'
  gem 'pry-rails'

  gem 'rubocop', '~> 1.13.0', require: false
  gem 'rubocop-minitest', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
end

group :development do
  gem 'bump', require: false

  gem 'better_errors', '>= 2.3.0'
  gem 'binding_of_caller'

  gem 'brakeman'

  gem 'listen', '>= 3.0.5', '< 3.6'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'

  gem 'web-console', '>= 3.3.0'
end

group :test do
  gem 'danger', '~> 8.2', require: false # Pull Request etiquette enforcement
  gem 'simplecov'
  # Faker added 0.5 seconds to the test suite per call. Haikunator seems much faster for faking strings
  gem 'haikunator'
  gem 'shoulda-matchers', '~> 4.5'

  gem 'json-schema', '~> 2.8.1'
  gem 'launchy'
  gem 'rdf-isomorphic', '~> 3.1.1'
  gem 'vcr', '5.0', require: false
  gem 'webdrivers', '~> 4.6'
  gem 'webmock', require: false
end

group :staging, :production do
  gem 'clamby'
end
