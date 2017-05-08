class Tnt
  InvalidZip = Class.new(StandardError)

  URL = 'http://ws.tntbrasil.com.br/servicos/CalculoFrete?wsdl'.freeze

  def initialize(shop, logger)
    @shop = shop
    @logger = logger
  end

  def quote(params)
    begin
      response = request(params)
    rescue Excon::Errors::Error
      return @shop.fallback_quote(request)
    end

    hash = response.to_hash
    log(hash)

    if errors = hash[:calcula_frete_response][:out][:error_list][:string]
      log(errors)
      return []
    end

    quote = [hash[:calcula_frete_response][:out].slice(:prazo_entrega, :vl_total_frete)]
    quote.map do |q|
      quotation = Quotation.find_or_initialize_by(
        shop_id: @shop.id,
        cart_id: params[:cart_id],
        package: params[:package].presence,
        delivery_type: @shop.tnt_delivery_type
      )
      quotation.name = "TNT"
      quotation.price = q[:vl_total_frete]
      quotation.deadline = q[:prazo_entrega]
      quotation.slug = 'tnt'
      quotation.deliver_company = "TNT"
      quotation.skus = params[:products].map { |product| product[:sku] }
      quotation.tap(&:save!)
    end
  end

  private

  def request(params)
    client = Savon.client(wsdl: URL)
    message = {
      "in0" => {
        "cdDivisaoCliente" => @shop.tnt_service_id,
        "cepDestino" => params[:shipping_zip],
        "cepOrigem" => @shop.zip.presence || request[:origin_zip],
        "login" => @shop.tnt_email,
        "nrIdentifClienteDest" => "0000000191",
        "nrIdentifClienteRem" => @shop.tnt_cnpj,
        "nrInscricaoEstadualDestinatario" => "",
        "nrInscricaoEstadualRemetente" => @shop.tnt_ie,
        "psReal" => formatted_weight(params),
        "senha" => "",
        "tpFrete" => "C",
        "tpPessoaDestinatario" => "F",
        "tpPessoaRemetente" => "J",
        "tpServico" => "RNC",
        "tpSituacaoTributariaDestinatario" => "CO",
        "tpSituacaoTributariaRemetente" => "CO",
        "vlMercadoria" => formatted_total(params)
      }
    }
    log(message)
    client.call(:calcula_frete, message: message)
  end

  def formatted_weight(params)
    weight = params[:products].sum { |i| i[:weight].to_f * i[:quantity].to_i }
    "%.3f" % weight
  end

  def formatted_total(params)
    "%.2f" % params[:order_total_price].to_f
  end

  def log(message, level = :info)
    @logger.tagged("TNT") { @logger.public_send(level, message) }
  end
end
