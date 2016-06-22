require 'rest_client'

class PlacesController < ApplicationController

  def index
    @shop = Shop.find(params[:shop_id])
    @method = ShippingMethod.find(params[:shipping_method_id])

    begin
      @method.check_and_update_places if @method.places.empty? || params[:force]
      @places = @method.places.order('id asc')
    rescue RestClient::Unauthorized
      flash.now[:'vnda-places-error'] = 'Loja não possui cadastro no vnda-places'
    end
  end

  def destroy
    Place.find(params[:id]).destroy
    @shipping_method = ShippingMethod.find(params[:shipping_method_id])
    @places = @shipping_method.places.order('id asc')
    render :index
  end
end
