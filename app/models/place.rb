class Place < ActiveRecord::Base

  VNDA_PLACES_HOST = ENV['VNDA_PLACES_HOST']

  belongs_to :shipping_method
  has_one :shop, through: :shipping_method

  validates :name, presence: true

  def self.retrieve_from_vnda_places_for(shop)
    response = RestClient.get("#{VNDA_PLACES_HOST}/places.json", {'X_STORE' => shop.name})
    JSON.parse(response)
  end
end
