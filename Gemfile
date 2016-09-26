source 'https://rubygems.org'

ruby '2.2.5'

gem 'rails', '4.2.7'
gem 'pg'
gem 'foreigner'
gem 'excon'
gem 'savon'
gem 'dotenv-rails'
gem 'rails_12factor', group: :production
gem 'rollbar', '~> 1.0.0'
gem 'puma', '3.5.2'
gem 'pry', group: :development
gem 'httparty', '0.13.5'
gem 'kaminari'
gem 'rest-client'
gem 'activerecord-postgis-adapter'
gem 'rails-env'
gem 'sidekiq'
gem 'nokogiri', '1.6.7.2'
gem 'sinatra', require: false

group :development, :staging, :production do
  gem "newrelic_rpm"
end

group :test do
  gem 'minitest-spec-rails'
  gem 'simplecov', :require => false
  gem 'mocha'
#  gem 'webmock'
end
