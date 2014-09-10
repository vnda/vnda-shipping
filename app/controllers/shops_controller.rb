class ShopsController < ApplicationController
  def index
    @shops = Shop.all
  end

  def new
    @shop = Shop.new
  end

  def create
    @shop = Shop.new(shop_params)
    if @shop.save
      success_redirect shop_shipping_methods_path(@shop)
    else
      render :new
    end
  end

  def edit
    @shop = Shop.find(params[:id])
  end

  def update
    @shop = Shop.find(params[:id])
    if @shop.update(shop_params)
      success_redirect shops_path
    else
      render :edit
    end
  end

  def destroy
    Shop.find(params[:id]).destroy!
    success_redirect shops_path
  end

  private

  def shop_params
    params.require(:shop).permit(:name, :axado_token, :forward_to_axado,
      :forward_to_correios, :correios_code, :correios_password,
      :normal_shipping_name, :express_shipping_name,
      correios_services: [])
  end
end
