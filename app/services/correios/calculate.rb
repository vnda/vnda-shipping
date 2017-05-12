class Correios::Calculate
  include ActiveModel::Model

  # TODO find other way to list these services
  SERVICES = {
    "04014" => 'SEDEX Varejo',
    "40045" => 'SEDEX a Cobrar Varejo',
    "40215" => 'SEDEX 10 Varejo',
    "40290" => 'SEDEX Hoje Varejo',
    "04510" => 'PAC Varejo',

    "04162" => 'SEDEX - Código Serviço 04162',
    "40436" => 'SEDEX - Código Serviço 40436',
    "40444" => 'SEDEX - Código Serviço 40444',
    "81019" => 'e-SEDEX - Código Serviço 81019',
    "04669" => 'PAC - Código Serviço 04669'
  }

  attr_accessor :shop, :delivery_type, :service_code, :enterprise_code, :enterprise_pass, :sender_zipcode, :track_ceps,
    :weight_tracks, :safety_margin, :log

  def initialize(shop_id, options = {})
    options = options.symbolize_keys

    self.shop            = Shop.find(shop_id) rescue nil
    self.enterprise_code = shop.correios_code
    self.enterprise_pass = shop.correios_password

    #options
    self.delivery_type   = DeliveryType.find(options[:delivery_type]) rescue nil
    self.service_code    = options[:service_code].presence || "04510"
    self.sender_zipcode  = options[:sender_zipcode]
    self.safety_margin   = options[:safety_margin].to_f

    track_id = ["40215", "40290", "81019"].include?(options[:service_code]) ? options[:service_code] : 0
    self.track_ceps      = TrackCep.where(service_code: track_id)
    self.weight_tracks   = TrackWeight.where(service_code: track_id)

    puts "Correios::Calculate ship_id: #{shop_id} options: #{options}"
  end

  validates :shop, :sender_zipcode, :delivery_type, :service_code, presence: true

  validate do |calculate|
    calculate.valid_shop?
    calculate.valid_delivery_type? if delivery_type.present?
    #calculate.valid_service_code? if service_code.present?
    calculate.valid_cep? if sender_zipcode.present?
    calculate.valid_safety_margin? if safety_margin.present?
  end

  def multiple_call
    @track_ceps.each do |cep|
      zipcode_start = cep.tracks[0]
      zipcode_end = cep.tracks[1]
      destination_zipcode = cep.tracks[2]

      @weight_tracks.each do |weight|
        weight.tracks.each do |w|
          begin
            single_call(
              destination_zipcode: destination_zipcode,
              weight: w,
              zipcode_start: zipcode_start,
              zipcode_end: zipcode_end
            )
          rescue
            AddSingleCorreiosZipcodeJob.perform_async(@shop.id,
              destination_zipcode: destination_zipcode,
              weight: w,
              zipcode_start: zipcode_start,
              zipcode_end: zipcode_end,

              delivery_type: @delivery_type.id,
              service_code: @service_code,
              sender_zipcode: @sender_zipcode,
              safety_margin: @safety_margin
            )
          end
        end
      end
    end
  end

  def single_call(options = {})
    options = options.symbolize_keys
    response = request(options) #destination_zipcode, weight[], zipcode_start, zipcode_end
    return "Correio error #{response["Erro"]}" unless response["Erro"] == "0"
    return "Valor zero" if response['Valor'] == "0,00"

    ActiveRecord::Base.transaction do
      method = create_method(
        min_weigth: options[:weight][0].to_s,
        max_weigth: options[:weight][1].to_s
      )

      create_rule(
        method,
        {
          min: unmask_cep(options[:zipcode_start]).to_i,
          max: unmask_cep(options[:zipcode_end]).to_i,
          price: price_with_safety_margin(safety_margin, response['Valor']),
          deadline: response['PrazoEntrega']
        }
      )

      #create_shop_zipcode_spreadsheet(
      #  zipcode_start: unmask_cep(options[:zipcode_start]),
      #  zipcode_end: unmask_cep(options[:zipcode_end]),
      #  weight_start: correios_weight(options[:weight][0]),
      #  weight_end: correios_weight(options[:weight][1]),
      #  absolute_money_cost: price_with_safety_margin(safety_margin, response['Valor']),
      #  price_percent: 0,
      #  price_by_extra_weight: 0,
      #  max_volume: 10000000,
      #  time_cost: response['PrazoEntrega'],
      #  country: 'BRA',
      #  minimum_value_insurance: 0
      #)
    end

    response
  end

  protected

  def request(options = {}) #:service_code, :enterprise_code, :enterprise_pass, :sender_zipcode, :destination_zip, medium_track(options[:weight])
    url = url(
      service_code || options[:service_code],
      enterprise_code || options[:enterprise_code],
      enterprise_pass || options[:enterprise_pass],
      sender_zipcode || options[:sender_zipcode],
      options[:destination_zipcode],
      medium_track(options[:weight])
    )
    puts "Correio::Calculate request: #{url}"
    response = Excon.get(url)
    puts "Correio::Calculate response: #{response.body}"
    parse_xml(response.body)
  end

  def create_method(options={}) #min_weigth, max_weigth
    method = @shop.methods.where( description: description(options[:min_weigth], options[:max_weigth]) ).first_or_initialize
    return method unless method.new_record?
    method.update_attributes(
      name: delivery_type.name,
      description: description(options[:min_weigth], options[:max_weigth]),
      min_weigth: options[:min_weigth],
      max_weigth: options[:max_weigth],
      data_origin: "local",
      delivery_type_id: delivery_type.id
    )
    method
  end

  def create_rule(method, options={}) #ShippingMethod, min, max, price, deadline
    rule = method.zip_rules.for_zip(options[:min].to_i).for_zip(options[:max].to_i).first_or_initialize
    rule.update_attributes(
      min: options[:min].to_i,
      max: options[:max].to_i,
      price: options[:price].to_f,
      deadline: options[:deadline].to_i
    )
  end

  #def create_shop_zipcode_spreadsheet(options={})
  #  @shop.zipcode_spreadsheets.create!(
  #    service_name: @delivery_type.name, service_code: @service_code, delivery_type_id: @delivery_type.id,
  #    zipcode_start: options[:zipcode_start], zipcode_end: options[:zipcode_end],
  #    weight_start: options[:weight_start], weight_end: options[:weight_end],
  #    absolute_money_cost: options[:absolute_money_cost], price_percent: options[:price_percent],
  #    price_by_extra_weight: options[:price_by_extra_weight], max_volume: options[:max_volume],
  #    time_cost: options[:time_cost], country: options[:country],
  #    minimum_value_insurance: options[:minimum_value_insurance]
  #  )
  #end

  def description(min_weigth, max_weigth)
    "Tabela #{SERVICES[service_code]} #{min_weigth} até #{max_weigth}"
  end

  def medium_track(weight)
    ((weight[1].to_f + weight[0].to_f) / 2).round(2)
  end

  def correios_weight(weight)
    BigDecimal.new(weight.to_f * 1000.0, 2)
  end

  def parse_response(options={})
    {
      zipcode_start: options[:zipcode_start],
      zipcode_end: options[:zipcode_start],
      weight_start: options[:weight_start],
      weight_end: options[:weight_end],
      absolute_money_cost: options[:absolute_money_cost],
      price_percent: 0,
      price_by_extra_weight: 0,
      max_volume: 10000000,
      time_cost: options[:time_cost],
      country: 'BRA',
      minimum_value_insurance: 0
    }
  end

  def parse_xml(xml)
    Hash.from_trusted_xml(xml)['Servicos']['cServico']
  end

  def unmask_cep(cep)
    cep.to_s.tr("-", "")
  end

  def parse_price(price)
    price.gsub('.', '').gsub(',', '.').to_f
  end

  def price_with_safety_margin(safety_margin, price)
    ((parse_price(price) * (safety_margin.to_i/100).to_i) + parse_price(price)).round(2)
  end

  def url(service_code, enterprise, pass, sender_zipcode, destination_zipcode, weight)
    "http://ws.correios.com.br/calculador/CalcPrecoPrazo.aspx?nCdEmpresa=#{enterprise}&sDsSenha=#{pass}&sCepOrigem=#{sender_zipcode}&sCepDestino=#{destination_zipcode}&nVlPeso=#{weight}&nCdFormato=1&nVlComprimento=16&nVlAltura=2&nVlLargura=11&sCdMaoPropria=n&nVlValorDeclarado=0.50&sCdAvisoRecebimento=n&nCdServico=#{service_code}&nVlDiametro=0&StrRetorno=xml"
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
    errors.add(:sender_zipcode, I18n.t('services.correios.calculate.invalid_sender_zipcode')) unless sender_zipcode.gsub(/[^\d]/, "").length == 8
  end

  def valid_safety_margin?
    errors.add(:safety_margin, I18n.t('services.correios.calculate.invalid_safety_margin')) unless [0,5,10,15,25].include?(safety_margin)
  end
end
