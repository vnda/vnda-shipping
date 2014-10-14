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

class DeliveryType < ActiveRecord::Base
  belongs_to :shop
  has_many :shipping_methods

end
