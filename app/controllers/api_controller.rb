class ApiController < ActionController::Base
  before_action :set_shop, only: [:quote, :delivery_date, :delivery_types]
  rescue_from InvalidZip && BadParams do
    head :bad_request
  end

  def delivery_types
    delivery_types = @shop.delivery_types.pluck(:name) || []
    render json: delivery_types || [], status: 200
  end

  def delivery_date
    period = params[:period]
    zip = params[:zip].to_i
    if @shop && zip
      unless period
        delivery_dates = @shop.available_periods(zip)
      else
        delivery_dates = @shop.check_period_rules(period)
      end
    end

    render json: delivery_dates || [], status: 200
  end

  def quote
    quotations = @shop.quote(request_params)
    quotations += forward_quote || [] unless check_express(quotations)

    render json: quotations, status: 200

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

  private

  def set_shop
    @shop = begin
      params[:token].present? ? Shop.find_by!(token: params[:token]) : Shop.find_by!(name: request.host)
    rescue ActiveRecord::RecordNotFound
      return head :unauthorized
    end
  end

  def forward_quote
    if @shop.forward_to_axado?
      Axado.quote(@shop.axado_token, request_params)
    elsif @shop.forward_to_correios?
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
        :weight
      ]
    )
  end
end
