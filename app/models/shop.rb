# == Schema Information
#
# Table name: shops
#
#  id                    :integer          not null, primary key
#  name                  :string(255)      not null
#  token                 :string(32)       not null
#  axado_token           :string(32)
#  forward_to_axado      :boolean          default(TRUE), not null
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

  before_create { self.token = SecureRandom.hex }
  after_create :create_delivery_types

  validates :name, presence: true, uniqueness: true
  validates  :axado_token, presence: true, if: 'forward_to_axado.present?'
  validates  :correios_code, :correios_password, presence: true, if: 'forward_to_correios.present?'

  def quote(params)
    zip = params[:shipping_zip].gsub(/\D+/, '').to_i
    weigth = params[:products].sum { |i| i[:weight].to_f }

    methods
      .where(enabled: true).joins(:delivery_type).where(delivery_types: { enabled: true })
      .for_weigth(weigth)
      .joins(:zip_rules)
      .merge(ZipRule.for_zip(zip))
      .pluck(:name, :price, :deadline, :express, :slug)
      .map do |n, p, d, e, s|
        Quotation.new(name: n, price: p.to_f, deadline: d, express: e, slug: s)
      end
  end

  def create_delivery_types
    self.delivery_types << DeliveryType.find_by(name: 'Normal')
    self.delivery_types << DeliveryType.find_by(name: 'Expressa')
    self.save(:validate => false)
  end

end
