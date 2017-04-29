require "rails_helper"

RSpec.describe Quotations do
  before { Timecop.freeze(2017, 3, 27, 17, 54, 55) }
  after { Timecop.return }

  it "raises an error if no valid parameters" do
    assert_raises Quotations::BadParams do
      Quotations.new(Shop.new, {}, Rails.logger)
    end
  end
end
