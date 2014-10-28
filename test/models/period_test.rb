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

class PeriodTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
