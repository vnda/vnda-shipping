# == Schema Information
#
# Table name: delivery_types
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  enabled    :boolean
#  created_at :datetime
#  updated_at :datetime
#

require 'test_helper'

class DeliveryTypeTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
