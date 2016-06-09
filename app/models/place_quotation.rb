PlaceQuotation = Struct.new(:name, :delivery_type, :delivery_type_slug, :price, :shipping_method_id, :slug) do
  def initialize(name:, delivery_type:, shipping_method_id:, slug:)
    self.name = name
    self.delivery_type = delivery_type || ''
    self.delivery_type_slug = 'places'
    self.price = 0
    self.shipping_method_id = shipping_method_id
    self.slug = slug
  end
end
