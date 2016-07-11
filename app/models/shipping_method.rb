# == Schema Information
#
# Table name: shipping_methods
#
#  id               :integer          not null, primary key
#  shop_id          :integer          not null
#  name             :string(255)      not null
#  description      :string(255)      default(""), not null
#  slug             :string(255)      not null
#  express          :boolean          default(FALSE), not null
#  enabled          :boolean          default(FALSE), not null
#  weigth_range     :numrange         not null
#  delivery_type_id :integer
#  data_origin      :string(255)      default("local"), not null
#  service          :string(255)
#

class ShippingMethod < ActiveRecord::Base

  belongs_to :shop
  belongs_to :delivery_type
  has_many :zip_rules, dependent: :destroy
  has_many :map_rules, dependent: :destroy
  has_many :places, dependent: :destroy
  has_many :block_rules, dependent: :destroy
  accepts_nested_attributes_for :zip_rules, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :map_rules, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :block_rules, allow_destroy: true, reject_if: :all_blank

  validates :name, :delivery_type_id, presence: true

  before_save :generate_slug, if: :description_changed?

  scope :for_weigth, -> weigth { where('shipping_methods.weigth_range @> ?', weigth.to_f) }
  scope :for_gmaps_origin, -> zip { where(data_origin: 'google_maps').merge(MapRule.for_zip(zip)).joins(:map_rules) }
  scope :for_locals_origin, -> zip { where(data_origin: 'local').merge(ZipRule.for_zip(zip)).joins(:zip_rules) }
  scope :for_places_origin, -> zip { where(data_origin: 'places').merge(Place.for_zip(zip)).joins(:places) }
  scope :for_places, -> { where(data_origin: 'places') }

  attr_writer :min_weigth, :max_weigth
  def min_weigth
    @min_weigth ||= weigth_range.try { |r| r.begin.infinite? ? nil : r.begin }
  end
  def max_weigth
    @max_weigth ||= weigth_range.try { |r| r.end.infinite? ? nil : r.end }
  end

  before_validation do
    self.weigth_range = Range.new(
      BigDecimal(min_weigth.blank? ? '-Infinity' : min_weigth),
      BigDecimal(max_weigth.blank? ? '+Infinity' : max_weigth)
    )
  end

  def generate_slug
    self.slug = description.to_s.split("CSV").first.to_s.strip.parameterize
  end

  def duplicate(shop_id = self.shop.id)
    self.class.new do |r|
      r.enabled     = false
      r.shop_id     = shop_id
      r.name        = "#{name} #{I18n.t('helpers.duplicate')}"
      r.description = description
      r.express     = express
      r.min_weigth  = min_weigth
      r.max_weigth  = max_weigth
      r.zip_rules.build(
        zip_rules.map { |rule| rule.slice(:min, :max, :price, :deadline) }
      )
    end
  end

  def copy_to_all_shops
    Shop.all.each do |shop|
      copy = duplicate(shop.id)
      copy.save! unless shop.methods.find_by(name: copy.name)
    end
  end

  def build_or_update_map_rules_from(xml_doc)
    factory = RGeo::Cartesian.factory

    xml_doc.css('Document Folder Placemark').collect do |placemark|
      name = placemark.css('name').text.strip
      points = placemark.css('Polygon coordinates').text.split(' ').collect{|z| c = z.split(','); c.pop; c.map(&:to_f)}.collect{|coordinates| factory.point(coordinates[0], coordinates[1])}
      region = factory.polygon(factory.line_string(points))

      if map_rule = self.map_rules.where(name: name).first
        map_rule.update_attribute(:region, region)
      else
        map_rule = MapRule.new(name: name, price: nil, deadline: nil, region: region)
      end

      map_rule
    end
  end

  def check_and_update_places
    Place.retrieve_from_vnda_places_for(self.shop).each do |place_json|
      self.places.create(name: place_json['name']) unless self.places.find_by_name(place_json['name'])
    end
  end
end
