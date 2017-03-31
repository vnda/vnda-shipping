class Correios
  URL = 'http://ws.correios.com.br/calculador/CalcPrecoPrazo.asmx?WSDL'.freeze
  FALLBACK_SHOP_NAME = "fallback".freeze

  #deprecated
  SERVICES = {
    40010 => 'SEDEX Varejo',
    40045 => 'SEDEX a Cobrar Varejo',
    40215 => 'SEDEX 10 Varejo',
    40290 => 'SEDEX Hoje Varejo',
    41106 => 'PAC Varejo',

    40096 => 'SEDEX - Código Serviço 40096',
    40436 => 'SEDEX - Código Serviço 40436',
    40444 => 'SEDEX - Código Serviço 40444',
    81019 => 'e-SEDEX - Código Serviço 81019',
    41068 => 'PAC - Código Serviço 41068'
  }

  #deprecated
  EXPRESS = [40010, 40045, 40215, 40290]

  MIN_WIDTH = 11
  MIN_HEIGHT = 2
  MIN_LENGTH = 16

  def initialize(shop, logger)
    @shop = shop
    @logger = logger
  end

  def quote(request)
    weight = request[:products].sum { |i| i[:weight].to_f * i[:quantity].to_i }
    if weight > 30
      log("package too heavy (#{weight})", :warn)
      return fallback_quote(request)
    end

    box = package_dimensions(request[:products])
    cubic_weight = (box[:length].to_f * box[:height].to_f * box[:width].to_f) / 6000.0
    if cubic_weight > 10.0 && cubic_weight < weight
      weight = cubic_weight
    end

    begin
      response = send_message(:calc_preco_prazo, {
        'nCdEmpresa' => @shop.correios_code,
        'sDsSenha' => @shop.correios_password,
        'nCdServico' => @shop.enabled_correios_service(request).join(?,),
        'sCepOrigem' => @shop.zip.presence || request[:origin_zip],
        'sCepDestino' => request[:shipping_zip],
        'nVlPeso' => weight,
        'nCdFormato' => 1,
        'nVlComprimento' => box[:length],
        'nVlAltura' => box[:height],
        'nVlLargura' => box[:width],
        'nVlDiametro' => 0,
        'sCdMaoPropria' => 'N',
        'sCdAvisoRecebimento' => 'N',
        'nVlValorDeclarado' => declared_value(request)
      }, request[:cart_id])
    rescue Wasabi::Resolver::HTTPError, Excon::Errors::Timeout
      return fallback_quote(request)
    end

    services = response.body[:calc_preco_prazo_response][:calc_preco_prazo_result][:servicos][:c_servico]
    services = [services] unless services.is_a?(Array)

    success, error = services.partition { |s| s[:erro] == '0' || s[:erro] == "010"}
    return fallback_quote(request) if success.empty? && error.any?

    error.each do |e|
      if e[:erro] == '-3'
        raise InvalidZip
      else
        log("#{e[:erro]}: #{e[:msg_erro]}", :error)
        @shop.add_shipping_error(e[:msg_erro])
      end
    end

    allowed, blocked = success.partition { |s| check_blocked_zip(request[:shipping_zip], s) }
    blocked.each do |s|
      log("Block rule found for service #{s[:codigo]}", :error)
    end

    Quotation.transaction do
      allowed.compact.map do |option|
        deadline = deadline_business_day(option[:erro] == '010' ? option[:prazo_entrega].to_i + 7 : option[:prazo_entrega].to_i)
        shipping_method = @shop.shipping_methods_correios.
          where(service: option[:codigo]).first

        quotation = Quotation.find_or_initialize_by(
          shop_id: @shop.id,
          cart_id: request[:cart_id],
          package: request[:package],
          delivery_type: shipping_type(shipping_method, option[:codigo])
        )
        quotation.shipping_method_id = shipping_method.id if shipping_method
        quotation.name = shipping_name(shipping_method, option[:codigo])
        quotation.price = parse_price(option[:valor])
        quotation.deadline = deadline
        quotation.slug = option[:codigo]
        quotation.deliver_company = "Correios"
        quotation.skus = request[:products].map { |product| product[:sku] }
        quotation.tap(&:save!)
      end
    end
  end

  def declared_value(request)
    return 0 unless @shop.declare_value
    order_total_price = request[:order_total_price].to_f
    return 17.0 if order_total_price < 17.0
    return 9999.99 if order_total_price > 9999.99
    order_total_price
  end

  private

  def send_message(method_id, message, cart_id)
    client = Savon.client(wsdl: URL, convert_request_keys_to: :none, open_timeout: 5, read_timeout: 5)
    request_xml = client.operation(method_id).build(message: message).to_s
    log("Request: #{request_xml}")
    response = client.call(method_id, message: message)
    log("Response: #{response.to_xml}")

    QuoteHistory.register(@shop.id, cart_id, {
      :external_request => request_xml,
      :external_response => response.to_xml
    })

    response
  end

  def package_dimensions(items)
    whl = (@shop.volume_for(items) ** (1 / 3.0)).ceil

    {
      width: [whl, MIN_WIDTH].max,
      height: [whl, MIN_HEIGHT].max,
      length: [whl, MIN_LENGTH].max
    }
  end

  def parse_price(str)
    str.gsub(/[.,]/, '.' => '', ',' => '.').to_f
  end

  def shipping_name(shipping_method, code)
    return shipping_method.name if shipping_method

    # DEPRECATED should not get here since shipping_method won't be nil
    config_name = if EXPRESS.include?(code.to_i)
      @shop.express_shipping_name
    else
      @shop.normal_shipping_name
    end

    config_name.presence || code
  end

  def shipping_type(shipping_method, code)
    return shipping_method.delivery_type.name if shipping_method

    # DEPRECATED should not get here since shipping_method won't be nil
    if EXPRESS.include?(code.to_i)
      "Expressa"
    else
      "Normal"
    end
  end

  def check_blocked_zip(zip, response)
    methods = @shop.shipping_methods_correios.where(service: response[:codigo].to_s)
    return true if methods.empty? # to compatibility to old config method

    blocked_methods = methods.joins(:block_rules).merge(BlockRule.for_zip(zip.to_i))
    if blocked_methods.any?
      methods = methods.where("id NOT IN (?)", blocked_methods.pluck(:id))
    end
    methods.any?
  end

  def deadline_business_day(deadline)
    today = Time.current.wday
    return deadline if deadline + today < 7

    partial = 6 - today
    full_weeks = (deadline - partial) / 7
    deadline + 1 + full_weeks
  end

  def fallback_quote(params)
    shop = Shop.where(name: FALLBACK_SHOP_NAME).first unless @shop.name == FALLBACK_SHOP_NAME
    return [] unless shop
    Quotations.new(shop, params, @logger).to_a
  end

  def log(message, level = :info)
    @logger.tagged("Correios") { @logger.public_send(level, message) }
  end
end
