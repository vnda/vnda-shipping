class DeliveryTypesController < ApplicationController
  before_filter { @shop = Shop.find(params[:shop_id]) }
  before_filter only: [:edit, :update, :toggle, :duplicate] do
    @delivery_type = @shop.delivery_types.find_by!(id: params[:id])
  end

  def index
    @delivery_types = @shop.delivery_types.order(:id)
  end

  def new
    @delivery_type = @shop.delivery_types.new
  end

  def create
    @delivery_type = @shop.delivery_types.new(delivery_type_params)
    if @delivery_type.save
      success_redirect shop_delivery_types_path(@shop)
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @delivery_type.update(delivery_type_params)
      success_redirect shop_delivery_types_path(@shop)
    else
      render :edit
    end
  end

  def toggle
    @delivery_type.update!(enabled: params[:enabled])
    head :ok
  end

  def destroy
    @shop.delivery_types.find_by!(id: params[:id]).destroy!
    success_redirect shop_delivery_types_path(@shop)
  end

  private

  def delivery_type_params
    params.require(:delivery_type).permit(
      :name, :enabled
      )
  end
end
