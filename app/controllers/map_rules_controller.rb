class MapRulesController < ApplicationController

  def index
    @shop = Shop.find(params[:shop_id])
    @method = ShippingMethod.find(params[:shipping_method_id])

    @map_rules = []  
  end

end