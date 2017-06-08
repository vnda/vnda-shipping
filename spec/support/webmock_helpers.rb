require "webmock/rspec"

module WebmockHelpers
  def request_fixture
    webmock_fixture("request")
  end

  def response_fixture
    webmock_fixture("response")
  end

  def webmock_fixture(type)
    dir = RSpec.current_example.metadata[:file_path].gsub("./spec/", "").gsub("_spec.rb", "")
    prefix = RSpec.current_example.description.sub(/^test_\d+_/, "").titleize.parameterize
    Rails.root.join("spec/fixtures/#{dir}/#{prefix}-#{type}.xml").read.strip
  end
end

RSpec.configure do |config|
  config.include WebmockHelpers
end
