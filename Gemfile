source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# Core Rails stuff
gem 'puma', '~> 3.7'
gem 'rails', '~> 5.1.1'

# Assets (CSS/JS) stuff
gem 'bootstrap', '~> 4.0.0.beta2.1'
gem 'font-awesome-rails'
gem 'jquery-rails'
gem 'sass-rails', '~> 5'
gem 'turbolinks', '~> 5'
gem 'uglifier', '>= 1.3.0'

# View stuff
gem 'activestorage'
gem 'simple_form'

# Hydra stuff
gem 'active-fedora', github: 'mbarnett/active_fedora', branch: 'fix_types_literally_do_nothing'
gem 'hydra-works'
gem 'rdf-vocab'
gem 'solrizer', github: 'mbarnett/solrizer', branch: 'literally_types'

# Database stuff
gem 'mysql2', '>= 0.3.18', '< 0.5'
gem 'redis', '~> 4.0'
gem 'rsolr'

# Authentication
gem 'omniauth'
gem 'omniauth-saml'

# Authorization
gem 'pundit'

# Background tasks
gem 'sidekiq', '~> 5.0'
gem 'sinatra' # used by sidekiq/web

# Misc Utilities
gem 'kaminari'

# Seeds
group :development, :test, :uat do
  gem 'faker', require: false
end

group :development, :test do
  gem 'sdoc', require: false

  gem 'capybara', '~> 2.15'
  gem 'selenium-webdriver', require: false

  gem 'pry'
  gem 'pry-rails'

  gem 'rubocop', '~> 0.51.0', require: false

  # Need to wait till scss_lint is using sass 3.5+
  # More details here: https://github.com/brigade/scss-lint/issues/877
  # gem 'scss_lint', '>= 0.55.0', require: false
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
