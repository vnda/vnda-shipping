class APIController < ActionController::Base
  before_action :instrument_requests
  before_action :set_shop, only: [:quotation_details, :quote, :delivery_date,
    :delivery_types, :delivery_periods, :local, :places, :shipping_methods,
    :sellers, :update_seller, :quotation, :update_place_name]

  rescue_from InvalidZip do
    render json: { error: "invalid zip" }, status: 400
  end

  rescue_from Quotations::BadParams do |ex|
    render json: { error: ex.message }, status: 400
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
      render json: {error: @shop.friendly_message_for("Não existem opções de entrega para este endereço")}, status: 400
    else
      render json: periods, status: 200
    end
  end

  def quote
    @quotations = PackageQuotations.new(@shop, allowed_params, logger).to_h

    logger.info(@quotations.to_json)
    unless @quotations.values.any? { |quotations| quotations.any? }
      message = @shop.add_shipping_error("Não existem opções de entrega para este endereço")
      render json: { error: @shop.friendly_message_for(message) }, status: 400
    end
  end

  def local
    map_rules = MapRule.joins(:shipping_method).where(shipping_methods: {shop_id: @shop.id}).joins(:shipping_method).where(shipping_methods: { enabled: true }).for_zip(params[:zip].sub('-', '')).select('shipping_methods.slug')
    render json: { local: map_rules.first.try(:slug) || find_local(@shop.zip_rules).first.try(:slug) || false }
  end

  def places
    render json: @shop.places_for_shipping_method(params[:shipping_method_id]).to_json(only: :name)
  end

  def update_place_name
    Place.includes(:shipping_method).where(
      name: params[:from],
      shipping_methods: {shop_id: @shop.id}
    ).each do |place|
      place.update_attribute(:name, params[:to])
    end
    head :ok
  end

  def shipping_methods
    render json: @shop.methods
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

  def sellers
    @sellers = @shop.shops.order(:name)
  end

  def update_seller
    if @shop.update(params.permit(:marketplace_tag))
      head :ok
    else
      render json: @shop.errors, status: 422
    end
  end

  def quotation
    @quotation = Quotation.
      joins(:shop).
      joins("LEFT JOIN shops marketplace ON (marketplace.id = shops.marketplace_id)").
      where("shops.id = ? OR marketplace.id = ?", @shop.id, @shop.id).
      where(package: params[:package_code], delivery_type_slug: params[:delivery_type_slug]).
      first!
  end

  private

  def set_shop
    logger.debug "Shop: #{env['HTTP_X_STORE']}"

    if params[:token].present?
      @shop = Shop.includes(:marketplace).find_by!(token: params[:token])
    else
      name = (env["HTTP_X_STORE"] || "unknown-host").split(':').first
      @shop = Shop.find_by!(name: name)
    end

    Honeybadger.context(shop_id: @shop.id)
  rescue ActiveRecord::RecordNotFound
    head :unauthorized
  end

  def allowed_params
    params.permit(
      :origin_zip, # TODO remove after all shops have zip set
      :shipping_zip,
      :order_total_price,
      :additional_price,
      :cart_id,
      products: {}
    ).tap { |whitelisted| whitelisted[:products] = params[:products] }
  end

  def find_local(collection)
    zip = collection.class.to_s.include?("ZipRule") ? params[:zip].gsub(/\D+/, '').to_i : params[:zip].gsub(/\D+/, '')
    collection.joins(:shipping_method).where(shipping_methods: { enabled: true }).for_zip(zip).select('shipping_methods.slug')
  end

  def instrument_requests
    I.increment("requests")
  end
end
