class ApiController < ActionController::Base
  before_action :set_shop, only: [:quotation_details, :quote, :delivery_date,
    :delivery_types, :delivery_periods, :local, :places, :shipping_methods]

  rescue_from InvalidZip, BadParams do
    head :bad_request
  end

  rescue_from ShippingProblem do |ex|
    render json: {error: @shop.friendly_message_for(ex.message)}, status: 400
  end

  def delivery_types
    delivery_types = @shop.delivery_types.pluck(:name) || []
    render json: delivery_types || [], status: 200
  end

  def delivery_date
    if @shop && params[:zip].present?
      delivery_dates =
        if params[:period].present?
          @shop.check_period_rules(params[:period])
        else
          date = Date.parse(params[:date]) if params[:date]
          @shop.available_periods(params[:zip].to_i, date)
        end
    end

    render json: delivery_dates || [], status: 200
  end

  def delivery_periods
    zip = params[:zip].to_s.gsub(/[^\d]/, '')
    num_days = (params[:num_days] || 7).to_i
    start_date = Date.parse(params[:start_date]) if params[:start_date]
    start_date = Date.current unless start_date

    if @shop && zip
      periods = []
      @shop.available_periods(zip).each do |period_name|
        periods << {
          name: period_name,
          delivery: @shop.delivery_days_list(num_days, start_date, zip, period_name)
        }
      end
    end

    if periods.nil? or periods.empty?
      render json: {error: @shop.friendly_message_for("Não existem opções de entrega para este endereço.")}, status: 400
    else
      render json: periods, status: 200
    end
  end

  def quote
    quotations = @shop.quote(request_params)

    if @shop.forward_to_correios? && @shop.enabled_correios_service.any?
      if quotations.empty? || !correios_completed?(@shop, quotations)
        quotations += Correios.new(@shop).quote(request_params)
      end
    end

    if @shop.forward_to_intelipost?
      quotations += Intelipost.quote(@shop.intelipost_token, request_params, @shop)
    end

    unless quotations.empty?
      quotations = group_lower_prices(quotations)
    end

    if params[:additional_deadline].present?
      quotations = apply_additional_deadline(quotations)
    end

    QuoteHistory.register(@shop.id, request_params[:cart_id], quotations: quotations.to_json)

    if quotations.empty?
      logger.warn("No methods available; shop: #{@shop.name} parameters: #{params}")
      message = "Não existem opções de entrega para este endereço."
      @shop.add_shipping_error(message)
      render json: { error: @shop.friendly_message_for(message) }, status: 400
    else
      # order shipping by price
      if @shop.order_by_price
        quotations = quotations.sort_by { |quote| quote['price'] }
      end

      render json: quotations, status: 200
    end
  end

  def local
    map_rules = MapRule.joins(:shipping_method).where(shipping_methods: {shop_id: @shop.id}).joins(:shipping_method).where(shipping_methods: { enabled: true }).for_zip(params[:zip].sub('-', '')).select('shipping_methods.slug')
    render json: { local: map_rules.first.try(:slug) || find_local(@shop.zip_rules).first.try(:slug) || false }
  end

  def places
    render json: @shop.places_for_shipping_method(params[:shipping_method_id]).to_json(only: :name)
  end

  def shipping_methods
    render json: @shop.methods
  end

  def group_lower_prices(quotations)
    quotations_group = quotations.group_by { |quote| quote[:delivery_type_slug] }
    lower = []

    quotations_group.each do |delivery_type|
      delivery_types = quotations_group[delivery_type[0]]
      lower << delivery_types.sort_by{|v| v.price}.first
    end

    return lower || []
  end

  def create_intelipost
    shop = Shop.find_by(token: params[:shop_token])
    intelipost_api = Intelipost::ShipmentOrderApi.new(shop)
    res = intelipost_api.create(params)

    if res["status"] == "OK"
      puts "ORDER #{res['content']['order_number']} CREATED ON INTELIPOST"
      render json: res, status: 200
    else
      render json: { error: "It could not be created" }, status: 400
    end
  end

  def shipped
    shop = Shop.find_by(token: params[:shop_token])
    intelipost_api = Intelipost::ShipmentOrderApi.new(shop)
    res = intelipost_api.shipped(params)

    render json: res, status: 200
  end

  def quotation_details
    @quote = @shop.quotes.where(cart_id: params[:cart_id].to_i).order("updated_at desc").first
    if @quote
      render "quote_histories/show", :layout => false
    else
      render "quote_histories/not_found", :layout => false
    end
  end

  private

  def set_shop
    logger.debug "Shop: #{env['HTTP_X_STORE']}"

    if params[:token].present?
      @shop = Shop.find_by!(token: params[:token])
    else
      name = (env["HTTP_X_STORE"] || "unknown-host").split(':').first
      @shop = Shop.find_by!(name: name) if name.present?
    end
  rescue ActiveRecord::RecordNotFound
    head :unauthorized
  end

  def correios_completed?(shop, quotations)
    correios_delivery_types = @shop.methods.where(enabled: true, data_origin: "correios").map{|m| m.delivery_type.name }.uniq
    if correios_delivery_types.any?
      delivery_types_quoted = quotations.map{|q| q.delivery_type}
      return (correios_delivery_types - delivery_types_quoted).empty?
    end
    true
  end

  def apply_additional_deadline(quotations)
    quotations.each do |quote|
      quote.deadline = quote.deadline.to_i + params[:additional_deadline].to_i
    end
  end

  def request_params
    params.permit(
      :origin_zip,
      :shipping_zip,
      :order_total_price,
      :additional_deadline,
      :additional_price,
      :cart_id,
      products: [
        :sku,
        :price,
        :height,
        :length,
        :width,
        :weight,
        :quantity
      ]
    )
  end

  def find_local(collection)
    zip = collection.class.to_s.include?("ZipRule") ? params[:zip].gsub(/\D+/, '').to_i : params[:zip].gsub(/\D+/, '')
    collection.joins(:shipping_method).where(shipping_methods: { enabled: true }).for_zip(zip).select('shipping_methods.slug')
  end
end
