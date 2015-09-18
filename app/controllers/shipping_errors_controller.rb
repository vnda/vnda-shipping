class ShippingErrorsController < ApplicationController
  before_filter { @shop = Shop.find(params[:shop_id]) }

  def index
    @shipping_errors = @shop.shipping_errors.order(:message)
  end
end