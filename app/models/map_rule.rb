class MapRule < ActiveRecord::Base

  belongs_to :shipping_method
  has_one :shop, through: :shipping_method
  has_and_belongs_to_many :periods

  validates :name, :price, :deadline, presence: true  

  scope :for_zip, ->(zip_code) do
    location = ZipCode.get_geolocation_for(zip_code)
    where("ST_CONTAINS(region, ST_GeomFromText('POINT(? ?)'))", location[:lng], location[:lat])    
  end
end
