require 'rest_client'

class PlacesController < ApplicationController

  def index
    @shop = Shop.find(params[:shop_id])
    @method = ShippingMethod.find(params[:shipping_method_id])
    @method.check_and_update_places
    @places = @method.places.order('id asc')
  end

end
