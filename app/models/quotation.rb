Quotation = Struct.new(:name, :price, :deadline, :slug, :delivery_type) do
  def initialize(name:, price:, deadline:, slug:, delivery_type:)
    self.name = name
    self.price = price
    self.deadline = deadline
    self.slug = slug
    self.delivery_type = delivery_type || ''
  end
end
