class ApiController < ActionController::Base
  before_action :set_shop, only: [:quote, :delivery_date, :delivery_types, :delivery_periods]
  rescue_from InvalidZip && BadParams do
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
    period = params[:period]
    zip = params[:zip].to_i
    date = Date.parse(params[:date]) if params[:date]

    if @shop && zip
      delivery_dates = period.present? ? @shop.check_period_rules(period) : @shop.available_periods(zip, date)
    end

    render json: delivery_dates || [], status: 200
  end

  def delivery_periods
    zip = params[:zip].to_s.gsub(/[^\d]/, '').to_i
    num_days = (params[:num_days] || 7).to_i
    start_date = Date.parse(params[:start_date]) if params[:start_date]
    start_date = Date.current unless start_date

    if @shop && zip > 0
      periods = []
      @shop.available_periods(zip).each do |period_name|
        periods << {
          name: period_name,
          delivery: @shop.delivery_days_list(num_days, start_date, zip, period_name)
        }
      end
# expected return
#[
#  {name: "Manhã", delivery: ["no", "close", "close", "close", "close", "yes", "yes"]},
#  {name: "Tarde", delivery: ["no", "close", "close", "close", "yes", "yes", "no"]}
#]
    end

    if periods.nil? or periods.empty?
      render json: {error: @shop.friendly_message_for("Não existem opções de entrega para este endereço.")}, status: 400
    else
      render json: periods, status: 200
    end
  end

  def quote
    quotations = @shop.quote(request_params)
    quotations += forward_quote || [] unless check_express(quotations)
    quotations = lower_prices(quotations) unless quotations.empty?

    if quotations.empty?
      puts "No methods available shop: #{@shop.name} parameters: #{params}"
      message = "Não existem opções de entrega para este endereço."
      @shop.add_shipping_error(message)
      render json: {error: @shop.friendly_message_for(message)}, status: 400
    else
      render json: quotations, status: 200
    end
  end

  def lower_prices(quotations)
    quotations_group = quotations.group_by { |quote| quote[:delivery_type_slug] }
    lower = []
    quotations_group.each do |delivery_type|
      delivery_types = quotations_group[delivery_type[0]]
      lower << delivery_types.sort_by{|v| v.price}.first
    end
    return lower || []
  end

  def check_express(quotations)
    express = false
    quotations.each do |q|
      if method = @shop.methods.find_by(name: q.name)
        express = true if method.delivery_type.name == 'Expressa'
      end
    end
    return express
  end

  def create_intelipost
    shop = Shop.find_by(vnda_token: params[:shop_token])
    intelipost_api = Intelipost::ShipmentOrderApi.new(shop)
    res = intelipost_api.create(params)

    render json: res, status: 200
  end

  def shipped
    shop = Shop.find_by(vnda_token: params[:shop_token])
    intelipost_api = Intelipost::ShipmentOrderApi.new(shop)
    res = intelipost_api.ready_for_shipment(params)

    render json: res, status: 200
  end

  private

  def set_shop
    logger.debug "Shop: #{env['HTTP_X_STORE']}"
    @shop = begin
      params[:token].present? ? Shop.find_by!(token: params[:token]) : Shop.find_by(name: (env['HTTP_X_STORE'] || "unknown-host").split(':').first)
    rescue ActiveRecord::RecordNotFound
      return head :unauthorized
    end
  end

  def forward_quote
    if @shop.forward_to_axado?
      Axado.quote(@shop.axado_token, request_params, @shop)
    elsif @shop.forward_to_intelipost?
      Intelipost.quote(@shop.intelipost_token, request_params, @shop)
    elsif @shop.forward_to_correios? && @shop.enabled_correios_service.any?
      Correios.new(@shop).quote(request_params)
    else

    end
  end

  def request_params
    params.permit(
      :origin_zip,
      :shipping_zip,
      :order_total_price,
      :aditional_deadline,
      :aditional_price,
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
end
