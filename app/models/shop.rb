class Shop < ActiveRecord::Base
  has_many :methods, class_name: 'ShippingMethod'

  before_create { self.token = SecureRandom.hex }

  validates :name, presence: true

  def quote_zip(zip)
    methods
      .joins(:zip_rules)
      .merge(ZipRule.for_zip(zip))
      .pluck(:name, :price, :deadline)
      .map { |n, p, d| Quotation.new(name: n, price: p, deadline: d) }
  end
end
