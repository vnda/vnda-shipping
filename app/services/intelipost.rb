module Intelipost
  extend self
  class InvalidZip < StandardError; end

  def quote(api_token, request, shop = nil)
    begin
      response = Excon.post(
        'https://api.intelipost.com.br/api/v1/quote_by_product',
        headers: { 'Content-Type' => 'application/json',
        'Accept' => 'application/json',
        'api_key' => 'e551dcee51c5233132e7a6f67af65618eb57d0715ef95b6d51b5cc08e6c6361b' },
        body: build_request(request).to_json
      )
    rescue Excon::Errors::BadRequest
      puts "Intelipost request: #{build_request(request).to_json}"
      puts "Intelipost response #{response[:body]}"

      json = JSON.parse(response[:body])

      @shop.add_shipping_error(json['messages']['text'])
      raise ShippingProblem, json['messages']['text']
    end

    if response.status == 503
      return activate_backup_method(request, shop)
    end

    begin
      data = JSON.parse(Zlib::GzipReader.new(StringIO.new(response[:body])).read)
    rescue Zlib::GzipFile::Error
      data = JSON.parse(response[:body])
    end

    cotation_id = data['content']['id']
    deliveries = data['content']['delivery_options'].map do |o|
      Quotation.new(
        cotation_id: cotation_id,
        name: o['description'],
        price: o['final_shipping_cost'],
        deadline: o['delivery_estimate_business_days'],
        slug: o['delivery_method_name'].parameterize,
        deliver_company: o['logistic_provider_name'],
        delivery_type: find_delivery_type(o['delivery_method_type'], o['description'])
      ) if is_number?(o['delivery_estimate_business_days'])
    end
    deliveries.compact!
    deliveries

  #rescue Excon::Errors::BadRequest, Zlib::GzipFile::Error
  #  if response[:body].include?('quote.destinationZipCode.invalid')
  #    raise InvalidZip
  #  elsif response[:body].include?('quote.no.delivery.options')
  #    []
  #  else
  #    puts "Intelipost request: #{build_request(request).to_json}"
  #    puts "Intelipost response #{response[:body]}"
  #    raise e
  #  end
  #end
  end

  private

  def is_number?(delivery_days)
    if /\A\d+\z/.match(delivery_days.to_s)
      if delivery_days.to_i > 0
        return true
      end
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

  def build_request(r)
    {
      origin_zip_code:      r[:origin_zip][0..4] + '-' + r[:origin_zip][5..7],
      destination_zip_code: r[:shipping_zip][0..4] + '-' + r[:shipping_zip][5..7],
      additional_information: {},
      products: r[:products].map do |i|
        {
          sku:            i[:sku],
          cost_of_goods:  i[:price],
          height:         i[:height],
          length:         i[:length],
          width:          i[:width],
          weight:         i[:weight],
          description:    '',
          quantity:       i[:quantity]
        }
      end
    }
  end

  def activate_backup_method(request, shop)
    Rails.logger.info("Backup mode activated for: #{shop.name}")
    return shop.quote(request, true)
  end

end
