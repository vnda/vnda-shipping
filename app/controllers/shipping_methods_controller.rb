class ShippingMethodsController < ApplicationController
  before_filter { @shop = Shop.find(params[:shop_id]) }

  before_filter only: [:edit, :update, :toggle] do
    @method = @shop.methods.find_by!(slug: params[:id])
  end

  def index
    @methods = @shop.methods.order(:id)
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
  end

  def update
    if @method.update(method_params)
      success_redirect edit_shop_shipping_method_path(@shop, @method)
    else
      render :edit
    end
  end

  def toggle
    @method.update!(enabled: params[:enabled])
    head :ok
  end

  def destroy
    @shop.methods.find_by!(slug: params[:id]).destroy!
    success_redirect shop_shipping_methods_path(@shop)
  end

  private

  def method_params
    params.require(:shipping_method).permit(
      :name, :description, :express, :enabled,
      zip_rules_attributes: [:id, :min, :max, :price, :deadline, :_destroy]
    )
  end
end
