class Quotations
  BadParams = Class.new(StandardError)

  def initialize(shop, params, logger)
    raise BadParams unless params[:shipping_zip] && params[:products]

    @shop = shop
    @params = params.dup
    @logger = logger
    @zip = @params.delete(:shipping_zip).gsub(/\D+/, "")
  end

  def to_a
    quotations = []

    if available_shipping_methods.where(data_origin: "local").any?
      quotations << available_shipping_methods.for_locals_origin(@zip.to_i).
        select("shipping_methods.*, price, deadline")
    end

    if available_shipping_methods.where(data_origin: "google_maps").any?
      quotations << available_shipping_methods.for_gmaps_origin(@zip).
        select("shipping_methods.*, price, deadline")
    end

    if available_shipping_methods.where(data_origin: "places").any?
      quotations << available_shipping_methods.for_places_origin(@zip.to_i).
        select("shipping_methods.*, 0 AS price, deadline")
    end

    weight = greater_weight(@params[:products])
    quotations = quotations.flat_map do |data_origin_methods|
      quotation_for(data_origin_methods.for_weigth(weight))
    end

    if @shop.forward_to_correios? && @shop.enabled_correios_service.any?
      if quotations.empty? || !correios_completed?(@shop, quotations)
        quotations += Correios.new(@shop, @logger).quote(@params.merge(shipping_zip: @zip))
      end
    end

    if @shop.forward_to_intelipost?
      quotations += Intelipost.new(@shop, @logger).quote(@params.merge(shipping_zip: @zip))
    end

    if @shop.forward_to_tnt?
      quotations += Tnt.new(@shop, @logger).quote(@params.merge(shipping_zip: @zip))
    end

    quotations = group_lower_prices(quotations) if quotations.present?
    quotations = apply_additional_deadline(quotations) if @params[:additional_deadline].present?
    quotations = apply_picking_time(quotations)

    quotations = quotations.sort_by { |quote| quote.price } if @shop.order_by_price?
    QuoteHistory.register(@shop.id, @params[:cart_id], quotations: quotations.to_json)
    quotations
  end

  protected

  def available_shipping_methods
    if @params[:backup]
      @shop.methods.where(id: @shop.backup_method_id)
    else
      @shop.methods.joins(:delivery_type).
        where(enabled: true, delivery_types: { enabled: true })
    end
  end

  def correios_completed?(shop, quotations)
    correios_delivery_types = @shop.methods.where(enabled: true, data_origin: "correios").map{|m| m.delivery_type.name }.uniq
    if correios_delivery_types.any?
      delivery_types_quoted = quotations.map { |q| q.delivery_type }
      return (correios_delivery_types - delivery_types_quoted).empty?
    end
    true
  end

  def group_lower_prices(quotes)
    quotes.group_by { |quote| quote.delivery_type_slug }.inject([]) do |lowers, (slug, quotes)|
      lowers << quotes.min_by { |quotation| quotation.price }
      lowers
    end
  end

  def apply_additional_deadline(quotations)
    quotations.each do |quote|
      quote.deadline = quote.deadline.to_i + @params[:additional_deadline].to_i
    end
  end

  def apply_picking_time(quotations)
    return quotations unless @shop.picking_times.where(enabled: true).any?
    quotations.each do |quote|
      quote.deadline = PickingTime.next_time(@shop.id) + quote.deadline.to_i
    end
  end

  def greater_weight(products)
    cubic_capacity = @shop.volume_for(products) / 6000
    total_weight = products.sum { |i| i[:weight].to_f * i[:quantity].to_i }
    cubic_capacity > total_weight ? cubic_capacity : total_weight
  end

  def quotation_for(shipping_methods)
    shipping_methods.map do |shipping_method|
      quotation = Quotation.new(
        shop_id: @shop.id,
        cart_id: @params[:cart_id],
        shipping_method_id: shipping_method.id,
        name: shipping_method.name,
        deadline: shipping_method.deadline,
        slug: shipping_method.slug,
        delivery_type: shipping_method.delivery_type.name,
        notice: shipping_method.notice,
        package: @params[:package],
        price: shipping_method.price,
        skus: @params[:products].map { |product| product[:sku] }
      )
      log(quotation.attributes.to_json)
      quotation.save!
      quotation
    end
  end

  def log(message)
    @logger.tagged(self.class.name) { @logger.info(message) }
  end
end
