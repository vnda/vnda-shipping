class ShippingMethodsController < ApplicationController
  before_filter { @shop = Shop.find(params[:shop_id]) }

  def index
    @methods = @shop.methods.all
  end

  def new
    @method = @shop.methods.new
  end

  def create
    @method = @shop.methods.new(method_params)
    if @method.save
      success_redirect edit_shop_shipping_method_path(@shop, @method)
    else
      render :new
    end
  end

  def edit
    @method = @shop.methods.find(params[:id])
  end

  def update
    @method = @shop.methods.find(params[:id])
    if @method.update(method_params)
      success_redirect edit_shop_shipping_method_path(@shop, @method)
    else
      render :edit
    end
  end

  def destroy
    @shop.methods.find(params[:id]).destroy!
    success_redirect shop_shipping_methods_path(@shop)
  end

  private

  def method_params
    params.require(:shipping_method).permit(
      :name, :description,
      zip_rules_attributes: [:id, :min, :max, :price, :deadline, :_destroy]
    )
  end
end
