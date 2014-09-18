class Correios
  URL = 'http://ws.correios.com.br/calculador/CalcPrecoPrazo.asmx?WSDL'

  SERVICES = {
    40010 => 'SEDEX Varejo',
    40045 => 'SEDEX a Cobrar Varejo',
    40215 => 'SEDEX 10 Varejo',
    40290 => 'SEDEX Hoje Varejo',
    41106 => 'PAC Varejo',
  }

  EXPRESS = [40010, 40045, 40215, 40290]

  def initialize(shop)
    @shop = shop
  end

  def quote(request)
    box = package_dimensions(request[:products])
    response = send_message(:calc_preco_prazo,
      'nCdEmpresa' => @shop.correios_code,
      'sDsSenha' => @shop.correios_password,
      'nCdServico' => @shop.correios_services.join(?,),
      'sCepOrigem' => request[:origin_zip],
      'sCepDestino' => request[:shipping_zip],
      'nVlPeso' => request[:products].sum { |i| i[:weight].to_f },
      'nCdFormato' => 1,
      'nVlComprimento' => box.l,
      'nVlAltura' => box.h,
      'nVlLargura' => box.w,
      'nVlDiametro' => 0,
      'sCdMaoPropria' => 'N',
      'nVlValorDeclarado' => request[:order_total_price],
      'sCdAvisoRecebimento' => 'N',
    )

    services = response.body[:calc_preco_prazo_response][:calc_preco_prazo_result][:servicos][:c_servico]

    success, error = services.partition { |s| s[:erro] == '0' }

    error.each do |e|
      if e[:erro] == '-3'
        raise InvalidZip
      else
        Rails.logger.error("#{e[:erro]}: #{e[:msg_erro]}")
      end
    end

    groups = success.partition { |s| EXPRESS.include?(s[:codigo].to_i) }
    express, normal = groups.flat_map do |group|
      group.min { |s1, s2| parse_price(s1[:valor]) <=> parse_price(s2[:valor]) }
    end
    [
      Quotation.new(
        name: @shop.express_shipping_name.presence || SERVICES[express[:codigo].to_i],
        price: parse_price(express[:valor]),
        deadline: express[:prazo_entrega].to_i,
        express: true,
        slug: SERVICES[express[:codigo].to_i].parameterize
      ),
      Quotation.new(
        name: @shop.normal_shipping_name.presence || SERVICES[normal[:codigo].to_i],
        price: parse_price(normal[:valor]),
        deadline: normal[:prazo_entrega].to_i,
        express: false,
        slug: SERVICES[normal[:codigo].to_i].parameterize
      )
    ]
  end

  private

  def send_message(method_id, message)
    client = Savon.client(wsdl: URL, convert_request_keys_to: :none)
    request_xml = client.operation(method_id).build(message: message).to_s
    Rails.logger.info("Request: #{request_xml}")
    response = client.call(method_id, message: message)
    Rails.logger.info("Response: #{response.to_xml}")
    response
  end

  def package_dimensions(items)
    dims = items.map { |i| i.values_at(:width, :height, :length) }
    dims.reject! { |ds| ds.any?(&:blank?) }
    BinPack.min_bounding_box(dims.map { |ds| BinPack::Box.new(*ds) })
  end

  def parse_price(str)
    str.gsub(/[.,]/, '.' => '', ',' => '.').to_f
  end
end
