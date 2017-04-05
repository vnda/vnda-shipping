class Quotation < ActiveRecord::Base
  belongs_to :shop

  validates_presence_of :shop_id, :cart_id, :name, :slug, :skus

  before_validation :cleanup_skus
  before_save :set_delivery_type_slug

  protected

  def set_delivery_type_slug
    self.delivery_type_slug = delivery_type.parameterize if delivery_type?
  end

  def cleanup_skus
    self.skus = skus.select(&:present?).uniq if skus?
  end
end
