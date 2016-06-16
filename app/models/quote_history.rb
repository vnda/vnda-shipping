class QuoteHistory < ActiveRecord::Base
  belongs_to :shop

  def self.register(shop_id, cart_id, params = {})
    if shop_id.present? && cart_id.present?
      history = find_or_create_by( {:shop_id => shop_id, :cart_id => cart_id} )
      history.external_request = params[:external_request] if params[:external_request].present?
      history.external_response = params[:external_response] if params[:external_response].present?
      history.quotations = params[:quotations] if params[:quotations].present?
      history.save
    end
  end
end
