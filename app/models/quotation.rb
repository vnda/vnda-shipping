Quotation = Struct.new(:name, :price, :deadline, :slug, :delivery_type, :delivery_type_slug, :deliver_company) do
  def initialize(name:, price:, deadline:, slug:, delivery_type:, deliver_company:)
    self.name = name
    self.price = price
    self.deadline = deadline
    self.slug = slug
    self.delivery_type = delivery_type || ''
    self.deliver_company = deliver_company || ''
    self.delivery_type_slug = delivery_type.try(:parameterize) || ''
  end
end
