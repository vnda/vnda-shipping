class Place < ActiveRecord::Base

  belongs_to :shipping_method
  has_one :shop, through: :shipping_method

  validates :name, presence: true  

end
