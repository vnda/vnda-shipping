class Shop < ActiveRecord::Base
  has_many :methods, class_name: 'ShippingMethod'

  before_create { self.token = SecureRandom.hex }

  validates :name, presence: true, uniqueness: true
  validates  :axado_token, presence: true, if: 'forward_to_axado.present?'
  validates  :correios_code, :correios_password, presence: true, if: 'forward_to_correios.present?'

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
