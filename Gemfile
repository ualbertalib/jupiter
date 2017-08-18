source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# Core Rails stuff
gem 'puma', '~> 3.7'
gem 'rails', '~> 5.1.1'

# Assets (CSS/JS) stuff
gem 'font-awesome-rails'
gem 'jquery-rails'
gem 'turbolinks', '~> 5'
gem 'uglifier', '>= 1.3.0'

gem 'bootstrap', '~> 4.0.0.alpha6'
# Review this after and update once bootstrap V4.0.0.alpha6+ come out,
#  latest versions use popper instead of tether
source 'https://rails-assets.org' do
  gem 'rails-assets-tether', '>= 1.3.3'
end

gem 'activestorage'
gem 'font-awesome-rails'

# View stuff
gem 'haml'
gem 'simple_form'

# Hydra stuff
gem 'hydra-works'
gem 'rdf-vocab'
gem 'solrizer', github: 'mbarnett/solrizer', branch: 'solrizable_path_types'

# Database stuff
gem 'mysql2', '>= 0.3.18', '< 0.5'
gem 'redis', '~> 3.0'
gem 'rsolr'

# Authentication
gem 'omniauth'
gem 'omniauth-saml'

# Authorization
gem 'pundit'

# Misc Utilities
gem 'kaminari'

group :development, :test do
  gem 'capybara', '~> 2.13'
  gem 'selenium-webdriver', require: false

  gem 'pry'
  gem 'pry-rails'

  gem 'rubocop', require: false
end

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'

  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'sdoc'
  gem 'web-console', '>= 3.3.0'
end

group :test do
  gem 'simplecov'
  # Faker added 0.5 seconds to the test suite per call. Haikunator seems much faster for faking strings
  gem 'haikunator'
  gem 'minitest-hooks'
  gem 'shoulda', require: false
end
