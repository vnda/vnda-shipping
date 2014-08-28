class ApiController < ActionController::Base
  def quote
    shop = begin
      Shop.find_by!(token: params[:token])
    rescue ActiveRecord::RecordNotFound
      return head :unauthorized
    end

    quotations = shop.quote_zip(request_params[:shipping_zip].gsub(/\D+/, '').to_i)
    if quotations.empty?
      quotations = begin
        Axado.quote(shop.axado_token, request_params)
      rescue Axado::InvalidZip
        return head :bad_request
      end
    end
    render json: quotations
  end

  private

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
