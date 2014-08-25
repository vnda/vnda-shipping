module Axado
  extend self
  class InvalidZip < StandardError; end

  def quote(api_token, request)
    response = Excon.post(
      'http://api.axado.com.br/v2/consulta/',
      query: { token: api_token },
      headers: { 'Content-Type' => 'application/json' },
      body: build_request(request).to_json,
      expects: [200]
    )
    data = JSON.parse(response.body)
    data['cotacoes'].map do |o|
      Quotation.new(
        name: o['servico_nome'],
        price: o['cotacao_preco'].gsub(/[.,]/, '.' => '', ',' => '.').to_f,
        deadline: o['cotacao_prazo'],
        express: express_service?(o['servico_metaname']),
        slug: o['servico_metaname'].gsub(?-, ?_),
      )
    end
  rescue Excon::Errors::BadRequest => e
    json = JSON.parse(e.response.body)
    if json['erro_id'] == 102
      raise InvalidZip
    else
      raise e
    end
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
