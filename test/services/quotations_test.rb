require "test_helper"

require_relative "quotations/correios"
require_relative "quotations/google_maps"
require_relative "quotations/intelipost"
require_relative "quotations/local"
require_relative "quotations/places"
require_relative "quotations/sort"

class QuotationsTest < ActiveSupport::TestCase
  include CorreiosQuotationsTest
  include GoogleMapsQuotationsTest
  include IntelipostQuotationsTest
  include LocalQuotationsTest
  include PlacesQuotationsTest
  include SortQuotationsTest

  setup do
    Timecop.freeze(2017, 3, 27, 17, 54, 55)
  end

  teardown do
    Timecop.return
  end

  test "raises an error if no valid parameters" do
    assert_raises Quotations::BadParams do
      Quotations.new(create_shop, {}, Rails.logger)
    end
  end

  def create_shop(attributes = {})
    Shop.create!({ name: 'Loja', token: "a1b2c3", zip: "03320000" }.reverse_merge(attributes))
  end
end
