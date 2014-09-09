module Correios
  extend self
  URL = 'http://ws.correios.com.br/calculador/CalcPrecoPrazo.asmx?WSDL'

  SERVICES = {
    40010 => 'SEDEX Varejo',
    40045 => 'SEDEX a Cobrar Varejo',
    40215 => 'SEDEX 10 Varejo',
    40290 => 'SEDEX Hoje Varejo',
    41106 => 'PAC Varejo',
  }

  EXPRESS = [40010, 40045, 40215, 40290]

  def quote(code, password, services, request)
    client = Savon.client(wsdl: URL, convert_request_keys_to: :none)
    box = package_dimensions(request[:products])
    response = client.call(:calc_preco_prazo, message: {
      'nCdEmpresa' => code,
      'sDsSenha' => password,
      'nCdServico' => services.join(?,),
      'sCepOrigem' => request[:origin_zip],
      'sCepDestino' => request[:shipping_zip],
      'nVlPeso' => request[:products].sum { |i| i[:weight] },
      'nCdFormato' => 1,
      'nVlComprimento' => box.l,
      'nVlAltura' => box.h,
      'nVlLargura' => box.w,
      'nVlDiametro' => 0,
      'sCdMaoPropria' => 'N',
      'nVlValorDeclarado' => request[:order_total_price],
      'sCdAvisoRecebimento' => 'N',
    })

    services = response.body[:calc_preco_prazo_response][:calc_preco_prazo_result][:servicos][:c_servico]
    services.map do |s|
      number = s[:codigo].to_i
      name = SERVICES[number]
      Quotation.new(
        name: name,
        price: s[:valor].gsub(/[.,]/, '.' => '', ',' => '.').to_f,
        deadline: s[:prazo_entrega].to_i,
        express: EXPRESS.include?(number),
        slug: name.parameterize,
      )
    end
  end

  def package_dimensions(items)
    dims = items.map { |i| i.values_at(:width, :height, :length) }
    dims.reject! { |ds| ds.any?(&:blank?) }
    BinPack.min_bounding_box(dims.map { |ds| BinPack::Box.new(*ds) })
  end
end
