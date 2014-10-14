class ShippingMethod < ActiveRecord::Base
  belongs_to :shop
  has_many :zip_rules, dependent: :destroy
  accepts_nested_attributes_for :zip_rules, allow_destroy: true, reject_if: :all_blank

  validates :name, presence: true, uniqueness: true

  before_save :generate_slug, if: :name_changed?

  scope :for_weigth, -> weigth { where('shipping_methods.weigth_range @> ?', weigth) }

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
    self.slug = name.try(:parameterize)
  end

  def to_param
    slug
  end

  def duplicate
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
end
