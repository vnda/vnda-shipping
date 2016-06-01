require 'rest_client'

class PlacesController < ApplicationController

  def index
    @method = ShippingMethod.find(params[:shipping_method_id])

    @places = @method.places.order('id asc')
  end

end
