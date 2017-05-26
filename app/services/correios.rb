class Correios
  URL = 'http://ws.correios.com.br/calculador/CalcPrecoPrazo.asmx?WSDL'.freeze
  FALLBACK_SHOP_NAME = "fallback".freeze

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
        "nCdEmpresa" => @shop.correios_code,
        "sDsSenha" => @shop.correios_password,
        "nCdServico" => @shop.enabled_correios_service(request["package"]).join(?,),
        "sCepOrigem" => @shop.zip.presence || request[:origin_zip],
        "sCepDestino" => request[:shipping_zip],
        "nVlPeso" => weight,
        "nCdFormato" => 1,
        "nVlComprimento" => box[:length],
        "nVlAltura" => box[:height],
        "nVlLargura" => box[:width],
        "nVlDiametro" => 0,
        "sCdMaoPropria" => "N",
        "sCdAvisoRecebimento" => receive_alert,
        "nVlValorDeclarado" => declared_value(request)
      }, request[:cart_id])
    rescue Wasabi::Resolver::HTTPError, Excon::Errors::Error => e
      Rollbar.error(e)
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
        shipping_method = @shop.shipping_methods_correios.
          where(service: option[:codigo].to_s.rjust(5, "0")).
          first!

        quotation = Quotation.find_or_initialize_by(
          shop_id: @shop.id,
          cart_id: request[:cart_id],
          package: request[:package].presence,
          delivery_type: shipping_method.delivery_type.name
        )
        quotation.shipping_method_id = shipping_method.id
        quotation.name = shipping_method.name
        quotation.price = parse_price(option[:valor])
        quotation.slug = shipping_method.slug
        quotation.deliver_company = "Correios"
        quotation.skus = request[:products].map { |product| product[:sku] }

        deadline = option[:prazo_entrega].to_i
        deadline += 7 if option[:erro] == '010'
        quotation.deadline = deadline_business_day(shipping_method, deadline)

        quotation.tap(&:save!)
      end
    end
  end

  def declared_value(request)
    return 0 unless @shop.declare_value

    value = request[:products].sum { |product| product[:price].to_f * product[:quantity].to_i }
    return 17.0 if value < 17.0
    return 9999.99 if value > 9999.99
    value
  end

  def deadline_business_day(shipping_method, deadline)
    days_off = shipping_method.days_off
    deadline_date = Date.today
    while deadline > 0
      deadline_date = deadline_date + 1
      deadline_date = deadline_date + 1 while days_off.include?(deadline_date.wday)

      deadline = deadline - 1
    end

    (deadline_date - Date.today).to_i
  end

  def receive_alert
    @shop.correios_receive_alert ? "S" : "N"
  end

  private

  def send_message(method_id, message, cart_id)
    client = Savon.client(wsdl: URL, convert_request_keys_to: :none, open_timeout: 5, read_timeout: 5)
    request_xml = client.operation(method_id).build(message: message).to_s
    log("Request: #{request_xml}")
    response = client.call(method_id, message: message)
    log("Response: #{response.to_xml}")

    QuoteHistory.register(@shop.id, cart_id, {
      external_request: request_xml,
      external_response: response.to_xml
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

  def check_blocked_zip(zip, response)
    methods = @shop.shipping_methods_correios.where(service: response[:codigo].to_s.rjust(5, "0"))
    return true if methods.empty? # to compatibility to old config method

    blocked_methods = methods.joins(:block_rules).merge(BlockRule.for_zip(zip.to_i))
    if blocked_methods.any?
      methods = methods.where("id NOT IN (?)", blocked_methods.pluck(:id))
    end
    methods.any?
  end

  def fallback_quote(params)
    shop = Shop.where(name: FALLBACK_SHOP_NAME).first unless @shop.name == FALLBACK_SHOP_NAME
    return [] unless shop
    Quotations.new(shop, params.merge(original_shop_id: @shop.id), @logger).to_a
  end

  def log(message, level = :info)
    @logger.tagged("Correios") { @logger.public_send(level, message) }
  end
end
