class Correios::Calculate
  include HTTParty
  include ActiveModel::Model

  attr_accessor :shop, :delivery_type, :service_code, :enterprise_code, :enterprise_pass, :zipcode_start, :track_ceps,
    :weight_tracks, :safety_margin, :log

  def initialize shop_id, options={}
    self.shop            = Shop.find(shop_id) rescue nil
    self.delivery_type   = DeliveryType.find(options[:delivery_type]) rescue nil
    self.service_code    = options[:service_code] || 41106
    self.enterprise_code = options[:enterprise_code]
    self.enterprise_pass = options[:enterprise_pass]
    self.zipcode_start   = options[:zipcode_start]
    self.track_ceps      = TrackCep.where(service_code: 0)
    self.weight_tracks   = TrackWeight.where(service_code: 0)
    self.safety_margin   = options[:safety_margin].to_f
  end

  validates :shop, :zipcode_start, :delivery_type, :service_code, presence: true

  validate do |calculate|
    calculate.valid_shop?
    calculate.valid_delivery_type? if delivery_type.present?
    #calculate.valid_service_code? if service_code.present?
    calculate.valid_cep? if zipcode_start.present?
    calculate.valid_safety_margin? if safety_margin.present?
  end

  def self.multiple_call! shop_id, options={}
    self.new(shop_id, options).multiple_call
  end

  def self.single_call! cep, weight
    self.new(shop_id, options).single_call(cep, weight)
  end

  def multiple_call
    @track_ceps.each do |cep|
      @weight_tracks.each do |weight|
        weight.tracks.each do |w|
          begin
            @response = HTTParty.get(url(@service_code, @enterprise_code, @enterprise_pass, unmask_cep(@zipcode_start), unmask_cep(cep.tracks[2]), medium_track(w)))

            if medium_track(w) > 0.0 and parse_price(parse_xml(@response.body)['Valor']) > 0.0
              ActiveRecord::Base.transaction do
                method = create_method(name: @delivery_type.name, description: description(correios_weight(w[0]), correios_weight(w[1])), min_weigth: correios_weight(w[0]), max_weigth: correios_weight(w[1]), data_origin: "local", delivery_type_id: delivery_type.id)
                create_rule(method, min: correios_weight(w[0]), max: correios_weight(w[1]), price: price_with_safety_margin(@safety_margin, parse_xml(@response.body)['Valor']), deadline: parse_xml(@response.body)['PrazoEntrega'])
                create_shop_zipcode_spreadsheet(
                  zipcode_start: unmask_cep(cep.tracks[0]), zipcode_end: unmask_cep(cep.tracks[1]),
                  weight_start: correios_weight(w[0]), weight_end: correios_weight(w[1]),
                  absolute_money_cost: price_with_safety_margin(@safety_margin, parse_xml(@response.body)['Valor']),
                  price_percent: 0, price_by_extra_weight: 0, max_volume: 10000000,
                  time_cost: parse_xml(@response.body)['PrazoEntrega'], country: 'BRA', minimum_value_insurance: 0
                )
              end
            end
          rescue
            AddSingleCorreiosZipcodeJob.perform_later(@shop.id,
              current_cep: cep.tracks[2], zipcode_start: unmask_cep(@zipcode_start),
              zipcode_end: unmask_cep(cep.tracks[2]), weight: w, service_code: @service_code,
              enterprise_code: @enterprise_code, enterprise_pass: @enterprise_pass,
              service_name: @delivery_type.name, delivery_type_id: @delivery_type.id,
              safety_margin: @safety_margin
            )
          end
        end
      end
    end
  end

  def single_call options={} #current_cep, zipcode_start, zipcode_end, weight
    @response = HTTParty.get(url(options[:service_code], options[:enterprise_code], options[:enterprise_pass], options[:zipcode_start], options[:current_cep], medium_track(options[:weight])))

    ActiveRecord::Base.transaction do
      method = create_method(name: options[:service_name], description: description(correios_weight(options[:weight][0]), correios_weight(options[:weight][1])), min_weigth: correios_weight(options[:weight][0]), max_weigth: correios_weight(options[:weight][1]), data_origin: "local", delivery_type_id: options[:delivery_type_id])
      create_rule(method, min: correios_weight(options[:weight][0]), max: correios_weight(options[:weight][1]), price: price_with_safety_margin(@safety_margin, parse_xml(@response.body)['Valor']), deadline: parse_xml(@response.body)['PrazoEntrega'])
      create_shop_zipcode_spreadsheet(
        zipcode_start: unmask_cep(options[:zipcode_start]), zipcode_end: unmask_cep(options[:zipcode_end]),
        weight_start: correios_weight(options[:weight][0]), weight_end: correios_weight(options[:weight][1]),
        absolute_money_cost: price_with_safety_margin(options[:safety_margin], parse_xml(@response.body)['Valor']),
        price_percent: 0, price_by_extra_weight: 0, max_volume: 10000000,
        time_cost: parse_xml(@response.body)['PrazoEntrega'], country: 'BRA', minimum_value_insurance: 0
      )
    end
  end

  protected

  def create_method options={}
    @shop.methods.create!(name: @delivery_type.name, description: description(options[:min_weigth], options[:max_weigth]), min_weigth: options[:min_weigth], max_weigth: options[:max_weigth], data_origin: "local", delivery_type_id: delivery_type.id)
  end

  def create_rule method, options={}
    rule = method.zip_rules.for_zip(options[:min].to_i).for_zip(options[:max].to_i).first_or_initialize
    rule.update_attributes(min: options[:min].to_i, max: options[:max].to_i, price: options[:price].to_f, deadline: options[:deadline].to_i)
  end

  def create_shop_zipcode_spreadsheet options={}
    @shop.zipcode_spreadsheets.create!(
      service_name: @delivery_type.name, service_code: @service_code, delivery_type_id: @delivery_type.id,
      zipcode_start: options[:zipcode_start], zipcode_end: options[:zipcode_end],
      weight_start: options[:weight_start], weight_end: options[:weight_end],
      absolute_money_cost: options[:absolute_money_cost], price_percent: options[:price_percent],
      price_by_extra_weight: options[:price_by_extra_weight], max_volume: options[:max_volume],
      time_cost: options[:time_cost], country: options[:country],
      minimum_value_insurance: options[:minimum_value_insurance]
    )
  end

  def description min_weigth, max_weigth
    "#{@delivery_type.name} CSV #{min_weigth} até #{max_weigth}"
  end

  def medium_track weight
    (weight[1].to_f - weight[0].to_f).round(2)
  end

  def correios_weight weight
    BigDecimal.new(weight.to_f * 1000.0, 2)
  end

  def parse_response options={}
    {
      zipcode_start: options[:zipcode_start], zipcode_end: options[:zipcode_start], weight_start: options[:weight_start],
      weight_end: options[:weight_end], absolute_money_cost: options[:absolute_money_cost], price_percent: 0,
      price_by_extra_weight: 0, max_volume: 10000000, time_cost: options[:time_cost], country: 'BRA',
      minimum_value_insurance: 0
    }
  end

  def parse_xml xml
    hash = Hash.from_trusted_xml(xml)['Servicos']['cServico']
  end

  def unmask_cep cep
    cep.tr '-', ''
  end

  def parse_price price
    price.gsub('.', '').gsub(',', '.').to_f
  end

  def price_with_safety_margin safety_margin, price
    ((parse_price(price) * (safety_margin.to_i/100).to_i) + parse_price(price)).round(2)
  end

  def url service_code, enterprise, pass, zipcode_start, zipcode_end, weight
    "http://ws.correios.com.br/calculador/CalcPrecoPrazo.aspx?nCdEmpresa=#{enterprise}&sDsSenha=#{pass}&sCepOrigem=#{zipcode_start}&sCepDestino=#{zipcode_end}&nVlPeso=#{weight}&nCdFormato=1&nVlComprimento=16&nVlAltura=2&nVlLargura=11&sCdMaoPropria=n&nVlValorDeclarado=0.50&sCdAvisoRecebimento=n&nCdServico=#{service_code}&nVlDiametro=0&StrRetorno=xml"
  end

  # Validations
  def valid_shop?
    errors.add(:shop, I18n.t('services.correios.calculate.invalid_service_code')) unless shop
  end

  def valid_delivery_type?
    errors.add(:delivery_type, I18n.t('services.correios.calculate.delivery_type_not_found')) unless delivery_type
  end

  def valid_service_code?
    errors.add(:service_code, I18n.t('services.correios.calculate.invalid_service_code')) unless TrackCep.find_by(service_code: service_code)
  end

  def valid_cep?
    errors.add(:zipcode_start, I18n.t('services.correios.calculate.invalid_zipcode_start')) unless zipcode_start.gsub(/[^\d]/, "").length == 8
  end

  def valid_safety_margin?
    errors.add(:safety_margin, I18n.t('services.correios.calculate.invalid_zipcode_start')) unless [0,5,10,15,25].include?(safety_margin)
  end
end
