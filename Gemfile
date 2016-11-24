source 'https://rubygems.org'

ruby '2.3.0'

gem 'rails', '4.2.7'
gem 'pg'
gem 'excon'
gem 'savon'
gem 'dotenv-rails'
gem 'rails_12factor', group: :production
gem 'rollbar', '~> 1.0.0'
gem 'puma', '3.5.2'
gem 'httparty', '0.13.5'
gem 'kaminari'
gem 'rest-client'
gem 'activerecord-postgis-adapter'
gem 'nokogiri', '1.6.7.2'
gem 'sidekiq'
gem 'sinatra', require: false

group :development do
  gem "byebug"
  gem "awesome_print"
  gem 'pry'
end

group :development, :staging, :production do
  gem "newrelic_rpm"  
end

group :test do
  gem 'minitest-spec-rails'
  gem 'simplecov', :require => false
  gem 'mocha'
end
