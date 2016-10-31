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
#  correios_services     :integer          default([]), not null
#  normal_shipping_name  :string(255)
#  express_shipping_name :string(255)
#  backup_method_id      :integer
#  intelipost_token      :string(255)
#  forward_to_intelipost :boolean          default(FALSE), not null
#

class Shop < ActiveRecord::Base
  has_many :methods, class_name: 'ShippingMethod', dependent: :destroy
  has_many :zip_rules, through: :methods
  has_many :map_rules, through: :methods
  has_many :delivery_types, dependent: :destroy
  has_many :periods, dependent: :destroy
  has_many :shipping_errors, class_name: 'ShippingError', dependent: :destroy
  has_many :shipping_friendly_errors, dependent: :destroy
  has_many :quotes, class_name: 'QuoteHistory', dependent: :destroy
  has_many :zipcode_spreadsheets

  before_create { self.token = SecureRandom.hex }
  after_create :create_delivery_types, :create_correios_methods

  validates :name, presence: true, uniqueness: true
  validates  :axado_token, presence: true, if: 'forward_to_axado.present?'
  validates  :correios_code, :correios_password, presence: true, if: 'forward_to_correios.present?'

  def friendly_message_for(message)
    self.shipping_friendly_errors.order(:created_at).each do |friendly_message|
      return friendly_message.message if message.include?(friendly_message.rule)
    end
    message
  end

  def add_shipping_error(message)
    unless self.shipping_errors.where(message: message).size > 0
      self.shipping_errors << ShippingError.new(message: message)
    end
  end

  def quote(params, backup=false)
    raise BadParams unless params[:shipping_zip] && params[:products]

    zip = params[:shipping_zip]
    formatted_zip = zip.gsub(/\D+/, '').to_i

    weight = greater_weight(params[:products])

    available_methods = backup ? methods.where(id: backup_method_id) : methods.where(enabled: true).joins(:delivery_type).where(delivery_types: { enabled: true })

    quotations = []
    quotations << available_methods.for_locals_origin(formatted_zip) if available_methods.where(data_origin: "local").any?
    quotations << available_methods.for_gmaps_origin(zip) if available_methods.where(data_origin: "google_maps").any?

    quotations.collect do |data_origin_methods|
      quotation_for(data_origin_methods.for_weigth(weight).pluck(:name, :price, :deadline, :slug, :delivery_type_id, :notice))
    end.flatten | quotations_for_places(available_methods, formatted_zip)
  end

  def quotations_for_places(available_methods, zip)
    available_methods.for_places_origin(zip).pluck(:id, :name, :deadline, :slug, :delivery_type_id, :notice).collect do |id, n, d, s, dt, notice|
      PlaceQuotation.new(
        name: n, 
        shipping_method_id: id, 
        deadline: d, 
        slug: s, 
        delivery_type: set_delivery_type(dt), 
        notice: notice || ''
      )
    end
  end

  def places_for_shipping_method(shipping_method_id)
    method = methods.find(shipping_method_id)
    method.places
  end

  def fallback_quote(request)
    Rails.logger.info("Backup mode activated for: #{name}")
    fallback_shop = Shop.where(name: "fallback").first
    return [] unless fallback_shop
    fallback_shop.quote(request)
  end

  def quotation_for(shipping_methods)
    shipping_methods.map do |n, p, d, s, dt, notice|
      Quotation.new(
        name: n, 
        price: p.to_f, 
        deadline: d, 
        slug: s, 
        delivery_type: set_delivery_type(dt), 
        deliver_company: "", 
        cotation_id: "",
        notice: notice || ''
      )
    end
  end

  def set_delivery_type(id)
    self.delivery_types.find(id).name || ''
  end

  def create_delivery_types
    self.delivery_types.where(name: "Normal").first_or_create(enabled: true)
    self.delivery_types.where(name: "Expressa").first_or_create(enabled: true)
  end

  def create_correios_methods
    if forward_to_correios
      self.methods.create(
        name: "Normal",
        enabled: true,
        description: "PAC",
        min_weigth: 0,
        max_weigth: 30,
        delivery_type_id: self.delivery_types.where(name: "Normal").first.id,
        data_origin: "correios",
        service: "41106"
      )

      self.methods.create(
        name: "Expressa",
        enabled: true,
        description: "SEDEX",
        min_weigth: 0,
        max_weigth: 30,
        delivery_type_id: self.delivery_types.where(name: "Expressa").first.id,
        data_origin: "correios",
        service: "40010"
      )
    end
  end

  def available_periods(zip, date = nil)
    available_periods = []
    unless self.zip_rules.empty? && self.map_rules.empty?
      if date.present?
        ['zip_rules', 'map_rules'].each do |shipping_rule|
          formatted_zip = shipping_rule == 'zip_rules' ? zip.to_i : zip
          self.send(shipping_rule).joins(:shipping_method).where(shipping_methods: {enabled: true}).for_zip(formatted_zip).each do |z|
            z.periods.each do |p|
              available_periods << p.name if p.available_on?(date)
            end
          end
        end
      else
        ['zip_rules', 'map_rules'].each do |shipping_rule|
          formatted_zip = shipping_rule == 'zip_rules' ? zip.to_i : zip
          self.send(shipping_rule).joins(:shipping_method).where(shipping_methods: {enabled: true}).for_zip(formatted_zip).order_by_limit.each do |z|
            available_periods += z.periods.order_by_limit.pluck(:name) unless z.periods.empty?
          end
        end
      end
    end
    return available_periods.uniq
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

  def volume_for(items)
    volumes = items.map{ |i| i.values_at(:width, :height, :length, :quantity)}
    volumes.map{|i| i.collect(&:to_f).reduce(:*)}.reduce(:+)
  end

  def greater_weight(products)
    cubic_capacity = volume_for(products) / 6000
    total_weight = products.sum { |i| i[:weight].to_f * i[:quantity].to_i }
    return cubic_capacity > total_weight ? cubic_capacity : total_weight
  end


  def data_origin
    {
      local: true,
      google_maps: true,
      places: true,
      correios: forward_to_correios,
      axado: forward_to_axado,
      intelipost: forward_to_intelipost,
    }
  end

  def enabled_origins
    data_origin.select{|k,v| v == true}.keys
  end

  def shipping_methods_correios
    methods.where(data_origin:"correios").where(enabled: true)
  end

  def enabled_correios_service
    shipping_methods_correios.pluck(:service)
  end

  def allowed_correios_services
    services = {}
    JSON.load(correios_custom_services).map{|service| services.merge!(service) } if correios_custom_services.present?
    services = Correios::SERVICES if services.empty?
    services
  end

  def delivery_day_status(date, zip, period_name)
    if (date >= Date.current)
      p = periods_for(:zip_rules, date, zip, period_name) | periods_for(:map_rules, date, zip, period_name)
      p.uniq.select{|v| v }.any? ? "yes" : "close"
    else
      "close"
    end
  end

  def delivery_days_list(num_days, date, zip, period_name)
    list = []
    num_days.times do
      list << delivery_day_status(date, zip, period_name)
      date += 1.day
    end
    list
  end

  private

  def periods_for(rules_type, date, zip, period_name)
    formatted_zip = rules_type == :zip_rules ? zip.to_i : zip

    send(rules_type).joins(:shipping_method).where(shipping_methods: {enabled: true}).for_zip(formatted_zip).order_by_limit.map do |zip_rule|
      periods = zip_rule.periods.where(name: period_name)
      periods = periods.valid_on(Time.zone.now.strftime("%T")) if date == Date.current
      periods = periods.select{|p| p.available_on?(date)}
      periods = periods.select{|p| p.check_days_ago?(date) }
      periods.select{|p| p.available_on?(date)}.any?
    end
  end
end
