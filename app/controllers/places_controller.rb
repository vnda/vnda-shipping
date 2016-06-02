require 'rest_client'

class PlacesController < ApplicationController

  def index
    @shop = Shop.find(params[:shop_id])
    @method = ShippingMethod.find(params[:shipping_method_id])

    begin
      @method.check_and_update_places
      @places = @method.places.order('id asc')
    rescue RestClient::Unauthorized
      flash.now[:'vnda-places-error'] = 'Loja não possui cadastro no vnda-places'
    end
  end

end
