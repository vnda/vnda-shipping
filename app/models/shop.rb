class Shop < ActiveRecord::Base
  belongs_to :marketplace, class_name: "Shop"
  has_many :shops, foreign_key: "marketplace_id"
  has_many :methods, class_name: 'ShippingMethod', dependent: :destroy
  has_many :zip_rules, through: :methods
  has_many :map_rules, through: :methods
  has_many :delivery_types, dependent: :destroy
  has_many :periods, dependent: :destroy
  has_many :shipping_errors, class_name: 'ShippingError', dependent: :destroy
  has_many :shipping_friendly_errors, dependent: :destroy
  has_many :quotes, class_name: 'QuoteHistory', dependent: :destroy
  has_many :quotations
  has_many :zipcode_spreadsheets
  has_many :picking_times

  before_validation :clean_zip
  before_create { self.token = SecureRandom.hex }
  after_create :create_delivery_types
  after_create :create_correios_methods, if: :forward_to_correios?

  validates_presence_of :name, :zip
  validates_presence_of :axado_token, if: :forward_to_axado?
  validates_presence_of :correios_code, :correios_password, if: :forward_to_correios?
  validates_uniqueness_of :name, allow_blank: true
  validates_format_of :zip, with: /\A\d+\z/, allow_blank: true
  validates_length_of :zip, is: 8, allow_blank: true

  def friendly_message_for(message)
    shipping_friendly_errors.order(:created_at).each do |friendly_message|
      return friendly_message.message if message.include?(friendly_message.rule)
    end
    message
  end

  def add_shipping_error(message)
    unless shipping_errors.where(message: message).size > 0
      shipping_errors << ShippingError.new(message: message)
    end
    message
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
    items.map { |item| item.values_at(:width, :height, :length, :quantity).
      map(&:to_f).reduce(:*) }.sum
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
    methods.where(data_origin: "correios").where(enabled: true).order(:id)
  end

  def enabled_correios_service(package = nil)
    services = shipping_methods_correios

    if package.present? && name.include?("taglivros")
      services = if package.starts_with?("kit-") || package.starts_with?("livro-")
        services.where(service: "20010")
      else
        services.where.not(service: "20010")
      end
    end

    services.pluck(:service)
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

  protected

  def clean_zip
    self.zip = zip.gsub(/\D+/, "") if zip?
  end

  def create_delivery_types
    delivery_types.where(name: "Normal").first_or_create(enabled: true)
    delivery_types.where(name: "Expressa").first_or_create(enabled: true)
  end

  def create_correios_methods
    methods.create!(
      name: "Normal",
      enabled: true,
      description: "PAC",
      min_weigth: 0,
      max_weigth: 30,
      delivery_type_id: self.delivery_types.where(name: "Normal").first.id,
      data_origin: "correios",
      service: "41106"
    )

    methods.create!(
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
