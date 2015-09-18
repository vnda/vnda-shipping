class ShippingFriendlyErrorsController < ApplicationController
  before_filter { @shop = Shop.find(params[:shop_id]) }

  def index
    @shipping_friendly_errors = @shop.shipping_friendly_errors.order(:id)
  end

  def new
    @shipping_friendly_error = @shop.shipping_friendly_errors.new
  end

  def create
    @shipping_friendly_error = @shop.shipping_friendly_errors.new(shipping_friendly_error_params)
    if @shipping_friendly_error.save
      success_redirect shop_shipping_friendly_errors_path(@shop, @shipping_friendly_error)
    else
      render :new
    end
  end

  def edit
  	@shipping_friendly_error = @shop.shipping_friendly_errors.find(params[:id])
  end

  def update
  	@shipping_friendly_error = @shop.shipping_friendly_errors.find(params[:id])
    if @shipping_friendly_error.update(shipping_friendly_error_params)
      success_redirect shop_shipping_friendly_errors_path(@shop, @shipping_friendly_error)
    else
      render :edit
    end
  end

  def destroy
    @shop.shipping_friendly_errors.find(params[:id]).destroy!
    success_redirect shop_shipping_friendly_errors_path(@shop)
  end

  def affected
  	@affected = []
  	@shipping_friendly_error = @shop.shipping_friendly_errors.find(params[:id])
  	@shop.shipping_errors.each do |error|
  		@affected << error if error.message.include?(@shipping_friendly_error.rule)
  	end
  end

  private

  def shipping_friendly_error_params
    params.require(:shipping_friendly_error).permit(:rule, :message)
  end
end
