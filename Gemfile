source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# Core Rails stuff
gem 'puma', '~> 3.11'
gem 'rails', '~> 5.1.1'

# Assets (CSS/JS) stuff
gem 'bootstrap', '~> 4.0.0'
gem 'dropzonejs-rails'
gem 'font-awesome-rails'
gem 'jquery-rails'
gem 'sass-rails', '~> 5'
gem 'select2-rails', '~> 4'
gem 'turbolinks', '~> 5'
gem 'uglifier', '>= 1.3.0'

# View stuff
gem 'active_link_to'
gem 'activestorage'
gem 'simple_form'

# Hydra stuff
gem 'active-fedora', github: 'mbarnett/active_fedora', branch: 'fix_types_literally_do_nothing'
gem 'hydra-works'
gem 'rdf-vocab'
gem 'solrizer', github: 'mbarnett/solrizer', branch: 'literally_types'

# Database stuff
gem 'pg', '~> 0.21.0'
gem 'redis', '~> 4.0'
gem 'rsolr'

# Authentication
gem 'omniauth'
gem 'omniauth-saml'

# Authorization
gem 'pundit'

# Background tasks
gem 'sidekiq', '~> 5.1'
gem 'sinatra' # used by sidekiq/web

# Misc Utilities
gem 'kaminari' # Pagination
gem 'ransack' # ActiveRecord search/filter
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

  gem 'capybara', '~> 2.18'
  gem 'nokogiri'
  gem 'selenium-webdriver', require: false

  gem 'pry'
  gem 'pry-rails'

  gem 'rubocop', '~> 0.51.0', require: false

  gem 'scss_lint', '>= 0.56.0', require: false
end

group :development do
  gem 'better_errors', '>= 2.3.0'
  gem 'binding_of_caller'

  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'web-console', '>= 3.3.0'
end

group :test do
  gem 'simplecov'
  # Faker added 0.5 seconds to the test suite per call. Haikunator seems much faster for faking strings
  gem 'haikunator'
  gem 'minitest-hooks'
  gem 'shoulda', require: false
end

group :staging, :production do
  gem 'clamby'
end
