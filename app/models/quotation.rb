Quotation = Struct.new(:name, :price, :deadline, :express, :slug) do
  def initialize(name:, price:, deadline:, express:, slug:)
    self.name = name
    self.price = price
    self.deadline = deadline
    self.express = express
    self.slug = slug
  end
end
