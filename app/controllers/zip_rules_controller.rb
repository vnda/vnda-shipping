class ZipRulesController < ApplicationController

  def index
    @shop = Shop.find(params[:shop_id])
    @method = ShippingMethod.find(params[:shipping_method_id])
    
    @zip_rules = @method.zip_rules.empty? ? 
      [@method.zip_rules.build] :
      @method.zip_rules.order('id desc').page(params[:page]).per(5)    
  end

  def create
    @shop = Shop.find(params[:shop_id])
    @method = ShippingMethod.find(params[:shipping_method_id])
    @zip_rule = @method.zip_rules.create(zip_rule_params)
    flash.now[:notice] = I18n.t('notices.zip_rule.create') if @zip_rule.persisted?
  end

  def update
    @zip_rule = ZipRule.find(params[:id])
    flash.now[:notice] = I18n.t('notices.zip_rule.update') if @zip_rule.update_attributes(zip_rule_params)
  end

  def destroy
    @zip_rule = ZipRule.find(params[:id])  
    @zip_rule.destroy
    flash.now[:notice] = I18n.t('notices.zip_rule.destroy')
  end

  private

  def zip_rule_params
    params.require(:zip_rule).permit(:min, :max, :price, :deadline, period_ids: [])
  end
end