ENV["RAILS_ENV"] ||= "test"
require File.expand_path('../../config/boot', __FILE__)

require 'simplecov'
SimpleCov.start('rails')

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require "minitest/spec"
require "minitest/mock"
require 'webmock/minitest'

class ActiveSupport::TestCase
  ActiveRecord::Migration.check_pending!

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all
  # Add more helper methods to be used by all tests here...
  extend MiniTest::Spec::DSL

  register_spec_type self do |desc|
    desc < ActiveRecord::Base if desc.is_a? Class
  end

  def request_fixture
    webmock_fixture("request")
  end

  def response_fixture
    webmock_fixture("response")
  end

  def webmock_fixture(type)
    dir = self.class.name.titleize.parameterize("_")
    prefix = name.sub(/^test_\d+_/, "").titleize.parameterize
    Rails.root.join("test/fixtures/#{dir}/#{prefix}-#{type}.xml").read.strip
  end
end
