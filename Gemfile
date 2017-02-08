source 'https://rubygems.org'

ruby '2.3.0'

gem 'rails', '4.2.7.1'
gem 'pg'
gem 'excon'
gem 'savon'
gem 'dotenv-rails'
gem 'rollbar', '~> 1.0.0'
gem 'puma', '3.5.2'
gem 'httparty', '0.13.5'
gem 'kaminari'
gem 'rest-client'
gem 'activerecord-postgis-adapter'
gem 'nokogiri', '1.6.7.2'
gem 'sidekiq'
gem 'jb', '0.4.1'
gem 'will_paginate', '~> 3.1.0'
gem 'will_paginate-bootstrap'

gem 'sinatra', require: false

group :development do
  gem "byebug"
  gem 'pry'
  gem "bullet"
end

group :test do
  gem 'minitest-spec-rails'
  gem 'webmock', '2.3.2'

  gem 'simplecov', require: false
end

group :development, :test do
  gem 'awesome_print', '1.7.0'
end

group :development, :staging, :production do
  gem "newrelic_rpm"
end

group :production do
  gem 'rails_12factor'
end
