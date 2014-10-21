source 'https://rubygems.org'

ruby '2.1.2'

gem 'rails', '4.1.5'
gem 'pg'
gem 'foreigner'
gem 'excon'
gem 'savon'
gem 'dotenv-rails'
gem 'rails_12factor', group: :production
gem 'rollbar', '~> 1.0.0'
gem 'puma'

group :development, :staging, :production do
  gem "newrelic_rpm"
end

group :test do
  gem 'minitest-spec-rails'
  gem 'simplecov', :require => false
end
