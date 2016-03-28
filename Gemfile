source 'https://rubygems.org'

ruby '2.1.5'

gem 'rails', '4.1.8'
gem 'pg'
gem 'foreigner'
gem 'excon'
gem 'savon'
gem 'dotenv-rails'
gem 'rails_12factor', group: :production
gem 'rollbar', '~> 1.0.0'
gem 'puma'
gem 'pry', group: :development
gem 'httparty', '0.13.5'
gem 'will_paginate'

group :development, :staging, :production do
  gem "newrelic_rpm"
end

group :test do
  gem 'minitest-spec-rails'
  gem 'simplecov', :require => false
  gem 'mocha'
  gem 'webmock'
end
