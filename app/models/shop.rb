class Shop < ActiveRecord::Base
  has_many :methods, class_name: 'ShippingMethod'

  before_create { self.token = SecureRandom.hex }

  validates :name, presence: true

  def quote(params)
    zip = params[:shipping_zip].gsub(/\D+/, '').to_i
    weigth = params[:products].sum { |i| i[:weight].to_f }

    methods
      .where(enabled: true)
      .for_weigth(weigth)
      .joins(:zip_rules)
      .merge(ZipRule.for_zip(zip))
      .pluck(:name, :price, :deadline, :express, :slug)
      .map do |n, p, d, e, s|
        Quotation.new(name: n, price: p.to_f, deadline: d, express: e, slug: s)
      end
  end
end
