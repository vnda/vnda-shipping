class ShopsController < ApplicationController
  protect_from_forgery except: [:create]

  def index
    @shops = Shop.order(:name)
  end

  def new
    @shop = Shop.new
  end

  def create
    @shop = Shop.new(shop_params)

    respond_to do |format|
      if @shop.save
        format.html { success_redirect shop_shipping_methods_path(@shop), notice: I18n.t(:create, scope: [:flashes, :store]) }
        format.json { render json:  @shop.token, status: 201 }
      else
        format.html { render :new }
        format.json { render json:  @shop }
      end
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
    params.require(:shop).permit(
      :name, :intelipost_token, :forward_to_intelipost,
      :axado_token, :forward_to_axado, :vnda_token,
      :forward_to_correios, :correios_code, :correios_password,
      :normal_shipping_name, :express_shipping_name, :backup_method_id)
    .merge(correios_custom_services: (params[:shop][:correios_custom_services] || [])
    .map{|i| JSON.parse(i)}.to_json )
  end
end
