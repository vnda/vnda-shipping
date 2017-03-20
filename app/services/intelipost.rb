class Intelipost
  InvalidZip = Class.new(StandardError)

  URL = 'https://api.intelipost.com.br/api/v1/quote_by_product'.freeze

  def initialize(shop, logger)
    @shop = shop
    @logger = logger
  end

  def quote(params)
    response = request(params)

    if response.status == 503
      return @shop.fallback_quote(request)
    end

    begin
      data = JSON.parse(Zlib::GzipReader.new(StringIO.new(response[:body])).read)
    rescue Zlib::GzipFile::Error
      data = JSON.parse(response[:body])
    end

    deliveries = data['content']['delivery_options'].map do |o|
      Quotation.create!(
        shop_id: @shop.id,
        cart_id: params[:cart_id],
        package: params[:package],
        quotation_id: data['content']['id'],
        name: o['description'],
        price: o['final_shipping_cost'],
        deadline: o['delivery_estimate_business_days'],
        slug: o['delivery_method_name'].parameterize,
        deliver_company: o['logistic_provider_name'],
        delivery_type: find_delivery_type(o['delivery_method_type'], o['description']),
        skus: params[:products].map { |product| product[:sku] }
      ) if number?(o['delivery_estimate_business_days'])
    end
    deliveries.compact!
    deliveries
  end

  private

  def number?(delivery_days)
    if /\A\d+\z/.match(delivery_days.to_s)
      return true if delivery_days.to_i > 0
    end
    false
  end

  def find_delivery_type(delivery_method, description)
    if express_service?(delivery_method)
      return 'Expressa'
    elsif description.include?('Retirar na Fábrica')
      return 'Retirada'
    else
      return 'Normal'
    end
  end

  def express_service?(metaname)
    !!(metaname =~ /EXPRESS/)
  end

  def normalize_params(params)
    normalized_params = {
      origin_zip_code: params[:origin_zip].insert(5, "-"),
      destination_zip_code: params[:shipping_zip].insert(5, "-"),
      additional_information: {},
      products: params[:products].map do |product|
        {
          sku: product[:sku],
          cost_of_goods: product[:price],
          height: product[:height],
          length: product[:length],
          width: product[:width],
          weight: product[:weight],
          description: "",
          quantity: product[:quantity]
        }
      end
    }

    if @shop
      normalized_params[:additional_information] = { sales_channel: @shop.name }
    end

    normalized_params
  end

  def request(params)
    params = normalize_params(params).to_json
    log(params)

    response = Excon.post(URL,
      headers: {
        "Content-Type" => "application/json",
        "Accept" => "application/json",
        "Api-Key" => @shop.intelipost_token
      },
      body: params
    )
  rescue Excon::Errors::BadRequest => ex
    log(ex.response[:body])

    json = JSON.parse(ex.response[:body])

    @shop.add_shipping_error(json['messages']['text'])
    raise ShippingProblem, json['messages']['text']
  end

  def log(message)
    @logger.tagged(self.class.name) { @logger.info(message) }
  end
end
