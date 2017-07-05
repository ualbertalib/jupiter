source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'bcrypt', '~> 3.1.7'
gem 'bootstrap'
gem 'haml'
gem 'hydra-works'
gem 'jquery-rails'
gem 'mysql2', '>= 0.3.18', '< 0.5'
gem 'popper_js'
gem 'rails', '~> 5.1.1'
gem 'rdf-vocab'
gem 'redis', '~> 3.0'
gem 'rsolr'
gem 'simple_form'
gem 'solrizer', github: 'mbarnett/solrizer', branch: 'solrizable_path_types'
gem 'turbolinks', '~> 5'
gem 'uglifier', '>= 1.3.0'

group :development, :test do
  gem 'capybara', '~> 2.13'
  gem 'pry'
  gem 'pry-rails'
  gem 'selenium-webdriver'
end

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'web-console', '>= 3.3.0'
end

group :test do
  gem 'simplecov'
  # Faker added 0.5 seconds to the test suite per call. Haikunator seems much faster for faking strings
  gem 'haikunator'
  gem 'minitest-hooks'
end
