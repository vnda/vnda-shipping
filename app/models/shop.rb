# == Schema Information
#
# Table name: shops
#
#  id                    :integer          not null, primary key
#  name                  :string(255)      not null
#  token                 :string(32)       not null
#  axado_token           :string(32)
#  forward_to_axado      :boolean          default(FALSE), not null
#  correios_code         :string(255)
#  correios_password     :string(255)
#  forward_to_correios   :boolean          default(FALSE), not null
#  correios_services     :integer          default([]), not null, is an Array
#  normal_shipping_name  :string(255)
#  express_shipping_name :string(255)
#

class Shop < ActiveRecord::Base
  has_many :methods, class_name: 'ShippingMethod', dependent: :destroy
  has_many :delivery_types, dependent: :destroy
  has_many :periods, dependent: :destroy
  has_many :zip_rules, through: :methods

  before_create { self.token = SecureRandom.hex }
  after_create :create_delivery_types

  validates :name, presence: true, uniqueness: true
  validates  :axado_token, presence: true, if: 'forward_to_axado.present?'
  validates  :correios_code, :correios_password, presence: true, if: 'forward_to_correios.present?'

  def quote(params)
    raise BadParams unless params[:shipping_zip] && params[:products]

    zip = params[:shipping_zip].gsub(/\D+/, '').to_i

    weight = greater_weight(params[:products])

    methods
      .where(enabled: true).joins(:delivery_type).where(delivery_types: { enabled: true })
      .for_weigth(weight)
      .joins(:zip_rules)
      .merge(ZipRule.for_zip(zip))
      .pluck(:name, :price, :deadline, :slug, :delivery_type_id)
      .map do |n, p, d, s, dt|
        Quotation.new(name: n, price: p.to_f, deadline: d, slug: s, delivery_type: set_delivery_type(dt))
      end
  end

  def set_delivery_type(id)
    self.delivery_types.find(id).name || ''
  end
  def create_delivery_types
    self.delivery_types.where(name: "Normal").first_or_create(enabled: true)
    self.delivery_types.where(name: "Expressa").first_or_create(enabled: true)
  end

  def available_periods(zip)
    available_periods = []
    unless self.zip_rules.empty?
      self.zip_rules.for_zip(zip).each do |z|
        available_periods += z.periods.pluck(:name) unless z.periods.empty?

      end
    end
    return available_periods
  end

  def check_period_rules(period)
    period = self.periods.find_by(name: period)
    if period && limit_time = period.limit_time.strftime('%T')
      now = Time.now
      if now.strftime('%T') >= limit_time
        delivery_date = period.next_day(now + 1.day)
        parsed_date = {day: delivery_date.day, year: delivery_date.year, month: delivery_date.month}
      else
        delivery_date = period.next_day(now)
        parsed_date = {day: delivery_date.day, year: delivery_date.year, month: delivery_date.month}
      end
    end
  end

  def package_dimensions(items)
    dims = items.map { |i| i.values_at(:width, :height, :length) }
    dims.reject! { |ds| ds.any?(&:blank?) }
    BinPack.min_bounding_box(dims.map { |ds| BinPack::Box.new(*ds) })
  end

  def greater_weight(products)
    cubic_capacity = package_dimensions(products).vol / 6000
    total_weight = products.sum { |i| i[:weight].to_f }
    return cubic_capacity > total_weight ? cubic_capacity : total_weight
  end

end
