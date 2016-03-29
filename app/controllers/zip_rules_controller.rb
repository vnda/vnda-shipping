class ZipRulesController < ApplicationController

  def index
    @shop = Shop.find(params[:shop_id])
    @method = ShippingMethod.find(params[:shipping_method_id])
    
    @zip_rules = @method.zip_rules.empty? ? 
      [@method.zip_rules.build] :
      @method.zip_rules.paginate(page: params[:page], per_page: 5)    
  end

  def create
    @method = ShippingMethod.find(params[:shipping_method_id])
    @zip_rule = @method.zip_rules.create(zip_rule_params)
    flash.now[:notice] = I18n.t('notices.zip_rule.create') if @zip_rule.persisted?
  end

  def update
    
  end

  private

  def zip_rule_params
    params.require(:zip_rule).permit(:min, :max, :price, :deadline, period_ids: [])
  end
end