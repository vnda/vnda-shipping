class ShippingMethod < ActiveRecord::Base
  belongs_to :shop
  has_many :zip_rules, dependent: :destroy
  accepts_nested_attributes_for :zip_rules, allow_destroy: true, reject_if: :all_blank

  validates :name, presence: true
  validates_associated :zip_rules

  before_save :generate_slug, if: :name_changed?

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
      r.zip_rules.build(
        zip_rules.map { |rule| rule.slice(:min, :max, :price, :deadline) }
      )
    end
  end
end
