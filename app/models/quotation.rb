Quotation = Struct.new(:name, :price, :deadline) do
  def initialize(name:, price:, deadline:)
    self.name = name
    self.price = price
    self.deadline = deadline
  end
end
