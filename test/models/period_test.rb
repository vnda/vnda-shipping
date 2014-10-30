# == Schema Information
#
# Table name: periods
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  limit_time :time
#  days_off   :text
#  created_at :datetime
#  updated_at :datetime
#  shop_id    :integer
#

require 'test_helper'

describe Period do
  let(:period_params) { periods(:one).attributes }
  let(:period) { Period.new period_params }

  it "is valid with valid params" do
    period.must_be :valid?
  end

  it "is invalid without a name" do
    period_params['name'] = nil

    period.wont_be :valid?
    period.errors[:name].must_be :present?
  end

end
