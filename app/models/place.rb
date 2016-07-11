class Place < ActiveRecord::Base

  VNDA_PLACES_HOST = ENV['VNDA_PLACES_HOST']

  belongs_to :shipping_method
  has_one :shop, through: :shipping_method

  validates :name, presence: true

  attr_writer :min, :max
  def min; @min ||= range.try(:min) end
  def max; @max ||= range.try(:max) end

  scope :for_zip, -> zip { where('places.range @> ?', zip) }

  before_validation do
    self.range = Range.new(*[min, max].map { |v| v.to_s.gsub(/\D/, '').to_i })
  end

  def self.retrieve_from_vnda_places_for(shop)
    response = RestClient.get("#{VNDA_PLACES_HOST}/places.json", {'X_STORE' => shop.name})
    JSON.parse(response)
  end
end
