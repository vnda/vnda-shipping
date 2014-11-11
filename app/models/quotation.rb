Quotation = Struct.new(:name, :price, :deadline, :express, :slug, :delivery_type) do
  def initialize(name:, price:, deadline:, express:, slug:, delivery_type:)
    self.name = name
    self.price = price
    self.deadline = deadline
    self.express = express
    self.slug = slug
    self.delivery_type = DeliveryType.find_by(id: delivery_type).name || ''
  end
end
