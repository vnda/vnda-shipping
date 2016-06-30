class MapRule < ActiveRecord::Base

  belongs_to :shipping_method
  has_one :shop, through: :shipping_method
  has_and_belongs_to_many :periods

  validates :name, :price, :deadline, presence: true

  scope :for_zip, ->(zip_code) do
    location = location_for_zip(zip_code)
    where("ST_CONTAINS(region, ST_GeomFromText('POINT(? ?)'))", location[:lng], location[:lat])
  end

  scope :order_by_limit, -> { joins(:periods).order("days_ago DESC, periods.limit_time") }

  def self.location_for_zip(zip_code)
    RequestStore.store[:location] ||= ZipCode.get_geolocation_for(zip_code)
  end
end
