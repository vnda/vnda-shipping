class MapRule < ActiveRecord::Base

  belongs_to :shipping_method
  has_one :shop, through: :shipping_method
  has_and_belongs_to_many :periods

  validates :name, :price, :deadline, presence: true  

end
