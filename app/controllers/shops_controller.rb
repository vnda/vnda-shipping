class ShopsController < ApplicationController
  protect_from_forgery except: [:create]

  def index
    @shops = Shop.includes(:marketplace).order(:name)
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
        format.json { render json: @shop }
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

  def set_shipping_order
    @shop = Shop.find(params[:id])
    @shop.update!(order_by_price: params[:enabled])
    head :ok
  end

  private

  def shop_params
    params.
      require(:shop).
      permit(:name, :intelipost_token, :forward_to_intelipost, :axado_token,
        :forward_to_axado, :order_prefix, :declare_value, :forward_to_correios,
        :correios_code, :correios_password, :normal_shipping_name,
        :forward_to_tnt, :tnt_email, :tnt_cnpj, :tnt_ie, :tnt_delivery_type,
        :express_shipping_name, :backup_method_id, :marketplace_id, :zip).
      merge(correios_custom_services: (params[:shop][:correios_custom_services] || []).map { |i| JSON.parse(i) }.to_json)
  end
end
