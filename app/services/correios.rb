class Correios
  URL = 'http://ws.correios.com.br/calculador/CalcPrecoPrazo.asmx?WSDL'

  #deprecated
  SERVICES = {
    40010 => 'SEDEX Varejo',
    40045 => 'SEDEX a Cobrar Varejo',
    40215 => 'SEDEX 10 Varejo',
    40290 => 'SEDEX Hoje Varejo',
    41106 => 'PAC Varejo',
  }

  #deprecated
  EXPRESS = [40010, 40045, 40215, 40290]

  MIN_WIDTH = 11
  MIN_HEIGHT = 2
  MIN_LENGTH = 16

  def initialize(shop)
    @shop = shop
  end

  def quote(request)
    box = package_dimensions(request[:products])
    cubic_weight = (box[:length].to_f* box[:height].to_f * box[:width].to_f) / 6000.0
    weight = request[:products].sum { |i| i[:weight].to_f * i[:quantity].to_i }
    if cubic_weight > 10.0 and cubic_weight < weight
      weight = cubic_weight
    end
    begin
      response = send_message(:calc_preco_prazo,
        'nCdEmpresa' => @shop.correios_code,
        'sDsSenha' => @shop.correios_password,
        'nCdServico' => @shop.enabled_correios_service.join(?,),
        'sCepOrigem' => request[:origin_zip],
        'sCepDestino' => request[:shipping_zip],
        'nVlPeso' => weight,
        'nCdFormato' => 1,
        'nVlComprimento' => box[:length],
        'nVlAltura' => box[:height],
        'nVlLargura' => box[:width],
        'nVlDiametro' => 0,
        'sCdMaoPropria' => 'N',
        'nVlValorDeclarado' => request[:order_total_price],
        'sCdAvisoRecebimento' => 'N',
      )
    rescue Wasabi::Resolver::HTTPError, Excon::Errors::Timeout
      return @shop.fallback_quote(request)
    end

    puts response.body

    services = response.body[:calc_preco_prazo_response][:calc_preco_prazo_result][:servicos][:c_servico]
    services = [services] unless services.is_a?(Array)

    success, error = services.partition { |s| s[:erro] == '0' || s[:erro] == "010"}

    error.each do |e|
      if e[:erro] == '-3'
        raise InvalidZip
      else
        Rails.logger.error("#{e[:erro]}: #{e[:msg_erro]}")
        @shop.add_shipping_error(e[:msg_erro])
        #raise ShippingProblem, e[:msg_erro]
      end
    end

    allowed, blocked = success.partition { |s| check_blocked_zip(request[:shipping_zip], s) }
    blocked.each do |s|
      Rails.logger.error("Block rule found for service #{s[:codigo]} #{@shop.allowed_correios_services[s[:codigo]] || SERVICES[s[:codigo].to_i]}") #SERVICES is deprecated
    end

    result = []
    allowed.compact.each do |option|
      deadline = option[:erro] == '010'? option[:prazo_entrega].to_i + 7 : option[:prazo_entrega].to_i

      result << Quotation.new(
        name: shipping_name(option[:codigo]),
        price: parse_price(option[:valor]),
        deadline: deadline,
        slug: (@shop.allowed_correios_services[option[:codigo]] || option[:codigo]).parameterize,
        delivery_type: shipping_type(option[:codigo]),
        deliver_company: "Correios",
        cotation_id: ''
      )
    end
    result
  end

  private

  def send_message(method_id, message)
    client = Savon.client(wsdl: URL, convert_request_keys_to: :none, open_timeout: 5, read_timeout: 5)
    request_xml = client.operation(method_id).build(message: message).to_s
    Rails.logger.info("Request: #{request_xml}")
    response = client.call(method_id, message: message)
    Rails.logger.info("Response: #{response.to_xml}")
    response
  end

  def package_dimensions(items)
    whl = (@shop.volume_for(items)**(1/3.0)).ceil
    {
      width: [whl, MIN_WIDTH].max,
      height: [whl, MIN_HEIGHT].max,
      length: [whl, MIN_LENGTH].max
    }
  end

  def parse_price(str)
    str.gsub(/[.,]/, '.' => '', ',' => '.').to_f
  end

  def shipping_name(code)
    method_name = @shop.shipping_methods_correios.where(service: code.to_s)
    return method_name.pluck(:name).first if method_name.any?

    #deprecated
    config_name = if EXPRESS.include?(code.to_i)
      @shop.express_shipping_name
    else
      @shop.normal_shipping_name
    end

    config_name.presence || @shop.allowed_correios_services[code] || SERVICES[code.to_i] #SERVICES is deprecated
  end

  #deprecated
  def shipping_type(code)
    method_name = @shop.shipping_methods_correios.where(service: code.to_s)
    return method_name.first.delivery_type.name if method_name.any?
    if EXPRESS.include?(code.to_i)
      "Expressa"
    else
      "Normal"
    end
  end

  def check_blocked_zip(zip, response)
    methods = @shop.shipping_methods_correios.where(service: response[:codigo].to_s)
    return true if methods.empty? #to compatibility to old config method
    blocked_methods = methods.joins(:block_rules).merge(BlockRule.for_zip(zip.to_i))
    if blocked_methods.any?
      methods = methods.where("id NOT IN (?)", blocked_methods.pluck(:id))
    end
    methods.any?
  end

end
