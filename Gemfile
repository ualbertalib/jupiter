source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# Core Rails stuff
gem 'image_processing' # for ActiveStorage Variants
gem 'puma', '~> 3.12'
gem 'rails', '~> 5.2.3'

# Assets (CSS/JS) stuff
gem 'bootstrap', '~> 4.3.1'
gem 'dropzonejs-rails'
gem 'font-awesome-rails'
gem 'jquery-rails'
gem 'sassc-rails', '~> 2.1'
gem 'selectize-rails'
gem 'turbolinks', '~> 5'
gem 'uglifier', '>= 1.3.0'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# View stuff
gem 'active_link_to'
gem 'simple_form'

# SEO
gem 'canonical-rails'

# RDF stuff
gem 'rdf-vocab'
gem 'acts_as_rdfable', github: 'mbarnett/acts_as_rdfable', tag: 'v0.01'

# Database stuff
gem 'connection_pool'
gem 'pg', '~> 1.1.4'
gem 'redis', '~> 4.1'
gem 'rsolr'

# Authentication
gem 'omniauth'
gem 'omniauth-saml'

# Authorization
gem 'pundit', '1.1.0'

# Background tasks
gem 'sidekiq', '~> 5.2'
gem 'sidekiq-unique-jobs'
gem 'sinatra', '~> 2.0.5' # used by sidekiq/web
# Sidekiq cron jobs
gem 'rufus-scheduler', '3.6.0' # https://github.com/ondrejbartas/sidekiq-cron/issues/199
gem 'sidekiq-cron'

# Misc Utilities
gem 'aasm' # state-machine management
gem 'addressable', '~> 2.6.0' # Replacement for the standard URI implementation
gem 'danger', '~> 6.0' # Pull Request etiquette enforcement
gem 'ezid-client', '~> 1.8.0'
gem 'jbuilder' # generate JSON objects
gem 'kaminari' # Pagination
gem 'rack-attack' # Rate limiting
gem 'ransack' # ActiveRecord search/filter
gem 'uuidtools'
gem 'voight_kampff' # bot detection
gem 'wicked' # Multi-step wizard

# Performance monitoring
gem 'skylight'
# resolve production errors in minutes
gem 'rollbar'

# Seeds
group :development, :test, :uat do
  gem 'faker', require: false
end

group :development, :test do
  gem 'sdoc', require: false

  gem 'capybara', '>= 2.15', '< 4.0'
  gem 'nokogiri'
  gem 'selenium-webdriver', require: false

  gem 'pry'
  gem 'pry-byebug'
  gem 'pry-rails'

  gem 'rubocop', '~> 0.71.0', require: false
  gem 'rubocop-performance'

  gem 'scss_lint', '>= 0.56.0', require: false
end

group :development do
  gem 'bump', require: false

  gem 'better_errors', '>= 2.3.0'
  gem 'binding_of_caller'

  gem 'brakeman'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'web-console', '>= 3.3.0'
end

group :test do
  gem 'simplecov'
  # Faker added 0.5 seconds to the test suite per call. Haikunator seems much faster for faking strings
  gem 'haikunator'
  gem 'minitest-hooks'
  gem 'shoulda-matchers', '~> 4.0'

  gem 'launchy'
  gem 'vcr', require: false
  # Easy installation and use of chromedriver to run system tests with Chrome
  gem 'chromedriver-helper'
  gem 'webmock', require: false
end

group :staging, :production do
  gem 'clamby'
end
