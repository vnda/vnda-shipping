source 'https://rubygems.org'

ruby '2.4.1'

gem 'rails', '4.2.8'
gem 'pg', '0.21.0'
gem 'excon', '0.57.0'
gem 'savon', '2.11.1'
gem 'honeybadger', '3.1.2'
gem 'puma', '3.9.1'
gem 'httparty', '0.15.5'
gem 'kaminari', '0.17.0'
gem 'rest-client', '2.0.2'
gem 'activerecord-postgis-adapter', '3.1.5'
gem 'nokogiri', '1.8.0'
gem 'sidekiq', '4.2.10'
gem 'jb', '0.4.1'
gem 'will_paginate', '3.1.6'
gem 'will_paginate-bootstrap', '1.0.1'
gem 'nickel', '0.1.6'
gem 'concurrent-ruby', '1.0.5', require: 'concurrent'

gem 'sinatra', '1.4.7', require: false
gem 'thor', '0.19.1', require: false

group :development do
  gem 'dotenv-rails', '2.1.1'
  gem 'byebug', '9.0.6'
  gem 'pry', '0.10.4'
  gem 'bullet', '5.4.0'
end

group :test do
  gem 'minitest', '5.10.1'
  gem 'minitest-spec-rails', '5.4.0'
  gem 'webmock', '2.3.2'
  gem 'timecop', '0.8.1'

  gem 'simplecov', '0.12.0', require: false
end

group :development, :test do
  gem 'rspec-rails', '3.6.0'
  gem 'awesome_print', '1.7.0'
end

group :production do
  gem 'rails_12factor', '0.0.3'
end
