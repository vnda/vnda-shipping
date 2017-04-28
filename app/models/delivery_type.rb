class DeliveryType < ActiveRecord::Base
  belongs_to :shop
  has_many :shipping_methods

  validates_presence_of :name, :shop_id
  validates_uniqueness_of :name, scope: :shop_id, case_sensitive: false, allow_blank: true

  before_validation :strip_name

  protected

  def strip_name
    self.name = name.strip if name?
  end
end

# == Schema Information
#
# Table name: delivery_types
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  enabled    :boolean
#  created_at :datetime
#  updated_at :datetime
#  shop_id    :integer
#
