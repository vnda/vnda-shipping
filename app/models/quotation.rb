Quotation = Struct.new(:name, :price, :deadline, :slug, :delivery_type, :delivery_type_slug) do
  def initialize(name:, price:, deadline:, slug:, delivery_type:)
    self.name = name
    self.price = price
    self.deadline = deadline
    self.slug = slug
    self.delivery_type = delivery_type || ''
    self.delivery_type_slug = delivery_type.try(:parameterize) || ''
  end
end
