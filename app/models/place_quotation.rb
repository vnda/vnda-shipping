PlaceQuotation = Struct.new(:name, :delivery_type, :delivery_type_slug, :price) do
  def initialize(name:, delivery_type:)
    self.name = name
    self.delivery_type = delivery_type || ''
    self.delivery_type_slug = 'places'
    self.price = 0
  end
end
