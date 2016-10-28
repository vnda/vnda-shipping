Quotation = Struct.new(:cotation_id, :name, :price, :deadline, :slug, :delivery_type, :delivery_type_slug, :deliver_company, :notice) do
  def initialize(name:, price:, deadline:, slug:, delivery_type:, deliver_company:, cotation_id:, notice:)
    self.name = name
    self.price = price
    self.deadline = deadline
    self.slug = slug
    self.delivery_type = delivery_type || ''
    self.deliver_company = deliver_company || ''
    self.cotation_id = cotation_id || ''
    self.delivery_type_slug = delivery_type.try(:parameterize) || ''
    self.notice = notice || ''
  end
end
