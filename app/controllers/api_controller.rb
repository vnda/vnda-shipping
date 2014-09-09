class ApiController < ActionController::Base
  rescue_from Axado::InvalidZip do
    head :bad_request
  end

  def quote
    @shop = begin
      Shop.find_by!(token: params[:token])
    rescue ActiveRecord::RecordNotFound
      return head :unauthorized
    end

    quotations = @shop.quote_zip(request_params[:shipping_zip].gsub(/\D+/, '').to_i)
    quotations = forward_quote if quotations.empty?
    render json: quotations
  end

  private

  def forward_quote
    if @shop.forward_to_axado?
      Axado.quote(@shop.axado_token, request_params)
    elsif @shop.forward_to_correios?
      Correios.quote(@shop.correios_code, @shop.correios_password,
                     @shop.correios_services, request_params)
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
