require 'rest_client'

class PlacesController < ApplicationController

  def index
    @shop = Shop.find(params[:shop_id])
    @method = ShippingMethod.find(params[:shipping_method_id])

    begin
      @method.check_and_update_places if params[:force]
      @places = @method.places.order('id asc')
    rescue RestClient::Unauthorized
      flash.now[:'vnda-places-error'] = 'Loja não possui cadastro no vnda-places'
    end
  end

  def update
    @place = Place.find(params[:id])
    flash.now[:notice] = I18n.t('notices.zip_rule.update') if @place.update_attributes(place_params)
  end

  def destroy
    @place = Place.find(params[:id])
    @place.destroy
    flash.now[:notice] = I18n.t('notices.zip_rule.destroy')
  end

  private

  def place_params
    params.require(:place).permit(:min, :max, :deadline)
  end
end
