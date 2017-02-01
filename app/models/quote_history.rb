class QuoteHistory < ActiveRecord::Base
  belongs_to :shop

  def self.register(shop_id, cart_id, params = {})
    if shop_id.present? && cart_id.present?
      history = find_or_create_by(shop_id: shop_id, cart_id: cart_id)
      history.external_request = params[:external_request].presence
      history.external_response = params[:external_response].presence
      history.quotations = params[:quotations].presence
      history.tap(&:save)
    end
  end
end
