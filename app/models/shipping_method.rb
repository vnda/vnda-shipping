class ShippingMethod < ActiveRecord::Base
  belongs_to :shop
  belongs_to :delivery_type
  has_many :zip_rules, dependent: :destroy
  has_many :map_rules, dependent: :destroy
  has_many :places, dependent: :destroy
  has_many :block_rules, dependent: :destroy

  serialize :days_off

  accepts_nested_attributes_for :zip_rules, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :map_rules, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :block_rules, allow_destroy: true, reject_if: :all_blank

  validates :name, :delivery_type_id, :description, presence: true
  validates_numericality_of :min_weigth, less_than_or_equal_to: :max_weigth, allow_blank: true
  validates_numericality_of :max_weigth, less_than_or_equal_to: 1000, greater_than_or_equal_to: :min_weigth, allow_blank: true

  before_save :set_weight
  before_save :generate_slug, if: :description_changed?

  scope :for_weigth, -> weigth { where('shipping_methods.weigth_range @> ?', weigth.to_f) }
  scope :for_gmaps_origin, -> zip { where(data_origin: 'google_maps').merge(MapRule.for_zip(zip)).joins(:map_rules) }
  scope :for_locals_origin, -> zip { where(data_origin: 'local').merge(ZipRule.for_zip(zip)).joins(:zip_rules) }
  scope :for_places_origin, -> zip { where(data_origin: 'places').merge(Place.for_zip(zip)).joins(:places) }
  scope :for_places, -> { where(data_origin: 'places') }

  attr_writer :min_weigth, :max_weigth

  def min_weigth
    (@min_weigth || weigth_range.begin).to_f
  end

  def max_weigth
    (@max_weigth || weigth_range.end).to_f
  end

  def self.default_scope
    order(norder: :asc)
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
    Shop.find_each do |shop|
      copy = duplicate(shop.id)
      copy.save! unless shop.methods.find_by(name: copy.name)
    end
  end

  def build_or_update_map_rules_from(xml_doc)
    factory = RGeo::Cartesian.factory

    xml_doc.css('Document Folder Placemark').map do |placemark|
      points = placemark.css('Polygon coordinates').text.split(' ').map do |z|
        lat, lon = z.split(",")[0...2].map(&:to_f)
        factory.point(lat, lon)
      end

      region = factory.polygon(factory.line_string(points))
      if region
        name = placemark.css('name').text.strip
        map_rule = map_rules.find_or_initialize_by(name: name)
        map_rule.region = region
        map_rule.save!
      end

      map_rule
    end
  end

  def check_and_update_places
    Place.retrieve_from_vnda_places_for(shop).each do |place_json|
      places.create(name: place_json['name']) unless places.find_by_name(place_json['name'])
    end
  end

  def next_delivery_date(now = nil)
    now ||= Time.now
    return now if days_off.blank? || days_off.reject(&:blank?).empty? || days_off.size == 8
    return now unless days_off.include?(now.wday.to_s)
    next_delivery_date(now + 1.day)
  end

  protected

  def set_weight
    self.min_weigth = @min_weigth.blank? ? 0.0 : @min_weigth.to_f
    self.max_weigth = @max_weigth.blank? ? 1000.0 : @max_weigth.to_f
    self.weigth_range = Range.new(min_weigth, max_weigth)
  end
end

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
