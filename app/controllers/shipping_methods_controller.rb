class ShippingMethodsController < ApplicationController
  before_filter { @shop = Shop.find(params[:shop_id]) }
  before_filter only: [:edit, :update, :toggle, :duplicate, :copy_to_all_shops] do
    @method = @shop.methods.find_by!(id: params[:id])
  end
  before_filter :set_delivery_types, only: [:edit, :new, :create, :update, :duplicate, :import, :import2, :execute]

  def index
    @methods = @shop.methods.order(:id)
  end

  def new
    @method = @shop.methods.new
    @method.max_weigth ||= 1000
  end

  def import
  end

  def import2
    @import = Correios::Calculate.new(@shop.id, {})
  end

  def execute
    @import = Correios::Calculate.new(@shop.id, import_params)

    if @import.valid?
      AddMultipleCorreiosZipcodeJob.perform_async(@shop.id, import_params)
      redirect_to import2_shop_shipping_methods_path(@shop), notice: "Processo de importacao iniciado. Acompanhe pelo sidekiq."
    else
      render :import2
    end
  end

  def import_line
    args = params[:line].gsub('"', '').split(",")
    service_name = DeliveryType.find(params[:delivery_type_id]).name
    min_weigth = (args[3] == 0 ? 0 : args[3].to_i / 1000.0).round(3).to_s
    max_weigth = (args[4] == 0 ? 0 : args[4].to_i / 1000.0).round(3).to_s
    description = "#{params[:service_id]} CSV #{min_weigth} até #{max_weigth}"

    if args[4].to_i > 0 && args[5].to_f > 0
      unless method = @shop.methods.find_by(name: service_name, description: description)
        method = @shop.methods.create!(
          name: service_name,
          description: description,
          min_weigth: min_weigth,
          max_weigth: max_weigth,
          data_origin: "local",
          delivery_type_id: params[:delivery_type_id]
        )
      end

      rule = method.zip_rules.for_zip(args[0].to_i).for_zip(args[1].to_i).first_or_initialize
      rule.update_attributes(
        min: args[0].to_i,
        max: args[1].to_i,
        price: args[5].to_f,
        deadline: args[9].to_i
      )
      if rule.errors.empty?
        render text: "ok"
      else
        render text: rule.errors, status: 422
      end
    else
      render text: "error", status: 422
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

  def norder
    ids = params[:norder]
    ids.each_with_index do |id, index|
      ShippingMethod.find(id).update(norder: index)
    end

    render json: { success: true }
  end

  def set_shipping_order
    @shop = Shop.find(params[:id])
    @shop.update!(order_by_price: params[:enabled])
    head :ok
  end

  private

  def set_delivery_types
    @delivery_types = @shop.delivery_types
  end

  def method_params
    params.require(:shipping_method).permit(
      :delivery_type_id, :name, :description, :enabled, :min_weigth, :max_weigth, :data_origin, :notice,
      :service, block_rules_attributes: [:id, :min, :max, :_destroy], days_off: [],
      zip_rules_attributes: [:id, :min, :max, :price, :deadline, :_destroy, period_ids: [] ]
    )
  end

  def import_params
    params.require(:correios_calculate).permit(
      :service_code, :delivery_type, :sender_zipcode, :safety_margin, :enterprise_code, :enterprise_pass
    )
  end
end
