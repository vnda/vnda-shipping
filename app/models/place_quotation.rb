PlaceQuotation = Struct.new(:name, :delivery_type, :deadline, :delivery_type_slug, :price, :shipping_method_id, :slug, :notice) do
  def initialize(name:, delivery_type:, shipping_method_id:, slug:, deadline:, notice:)
    self.name = name
    self.delivery_type = delivery_type || ''
    self.delivery_type_slug = 'places'
    self.price = 0
    self.deadline = deadline
    self.shipping_method_id = shipping_method_id
    self.slug = slug,
    self.notice = notice || ''
  end
end
