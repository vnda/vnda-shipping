module Axado
  extend self
  class InvalidZip < StandardError; end

  def quote(api_token, request, shop = nil)
    response = Excon.post(
      'http://api.axado.com.br/v2/consulta/',
      query: { token: api_token },
      headers: { 'Content-Type' => 'application/json' },
      body: build_request(request).to_json,
      expects: [200, 503]
    )

    if response.status == 503
      return @shop.fallback_quote(request)
    end

    data = JSON.parse(response.body)
    data['cotacoes'].map do |o|
      Quotation.new(
        name: o['servico_nome'],
        price: o['cotacao_preco'].gsub(/[.,]/, '.' => '', ',' => '.').to_f,
        deadline: o['cotacao_prazo'],
        slug: o['servico_metaname'].gsub(?-, ?_),
        delivery_type: express_service?(o['servico_metaname']) ? 'Expressa' : 'Normal',
        deliver_company: "",
        cotation_id: ""
      )
    end
  rescue Excon::Errors::BadRequest => e
    json = JSON.parse(e.response.body)

    @shop.add_shipping_error(json['erro_msg'])
    raise ShippingProblem, json['erro_msg']
  end

  private

  def express_service?(metaname)
    !!(metaname =~ /sedex|expresso/)
  end

  def build_request(r)
    {
      cep_origem:       r[:origin_zip],
      cep_destino:      r[:shipping_zip],
      valor_notafiscal: r[:order_total_price],
      prazo_adicional:  r[:aditional_deadline],
      preco_adicional:  r[:aditional_price],
      volumes: r[:products].map do |i|
        {
          sku:         i[:sku],
          preco:       i[:price],
          altura:      i[:height],
          comprimento: i[:length],
          largura:     i[:width],
          peso:        i[:weight],
        }
      end
    }
  end
end
