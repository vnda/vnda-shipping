class ShippingMethod < ActiveRecord::Base
  belongs_to :shop
  has_many :zip_rules # validar intervalos
end
