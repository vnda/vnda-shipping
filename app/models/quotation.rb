class Quotation < ActiveRecord::Base
  belongs_to :shop

  validates_presence_of :shop_id, :cart_id, :name, :slug

  before_save :set_delivery_type_slug

  protected

  def set_delivery_type_slug
    self.delivery_type_slug = delivery_type.parameterize if delivery_type?
  end
end
