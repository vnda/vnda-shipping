class ShippingMethodsController < ApplicationController
  before_filter { @shop = Shop.find(params[:shop_id]) }
  before_filter only: [:edit, :update, :toggle, :duplicate, :copy_to_all_shops] do
    @method = @shop.methods.find_by!(id: params[:id])
  end
  before_filter :set_delivery_types, only: [:edit, :new, :create, :update, :duplicate, :import, :execute]
  before_filter :set_correios_services, only: [:edit, :new, :create, :update, :duplicate, :import, :execute]

  def index
    @methods = @shop.methods.order(:id)
  end

  def new
    @method = @shop.methods.new
  end

  def import
    @import = Correios::Calculate.new(@shop.id, {})
  end

  def execute
    @import = Correios::Calculate.new(@shop.id, import_params)

    if @import.valid?
      AddMultipleCorreiosZipcodeJob.perform_async(@shop.id, import_params)
      redirect_to import_shop_shipping_methods_path(@shop), notice: "Processo de importacao iniciado. Acompanhe pelo sidekiq."
    else
      render :import
    end

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
    @shop.methods.find_by!(id: params[:id]).destroy!
    success_redirect shop_shipping_methods_path(@shop)
  end

  def duplicate
    @method = @method.duplicate
    render :new
  end

  def copy_to_all_shops
    @method.copy_to_all_shops
    success_redirect shop_shipping_methods_path(@shop)
  end
  private

  def set_delivery_types
    @delivery_types = @shop.delivery_types
  end

  def set_correios_services
    @correios_services = @shop.allowed_correios_services
  end

  def method_params
    params.require(:shipping_method).permit(
      :delivery_type_id, :name, :description, :enabled, :min_weigth, :max_weigth, :data_origin, :notice,
      :service, block_rules_attributes: [:id, :min, :max, :_destroy],
      zip_rules_attributes: [:id, :min, :max, :price, :deadline, :_destroy, period_ids: [] ]
    )
  end

  def import_params
    params.require(:correios_calculate).permit(
      :service_code, :delivery_type, :sender_zipcode, :safety_margin, :enterprise_code, :enterprise_pass
    )
  end
end
