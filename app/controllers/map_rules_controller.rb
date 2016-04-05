require 'rest_client'

class MapRulesController < ApplicationController

  def index
    @shop = Shop.find(params[:shop_id])
    @method = ShippingMethod.find(params[:shipping_method_id])

    @map_rules = []  
  end

  def download_kml
    begin
      response = RestClient.get 'https://www.google.com/maps/d/kml', {params: {mid: params[:shipping_method][:mid], forcekml: '1'}}
      xml_doc  = Nokogiri::XML(response)

      @shop = Shop.find(params[:shop_id])
      @method = ShippingMethod.find(params[:shipping_method_id])
      @method.update_attributes(shipping_method_params)      
      
      @map_rules = xml_doc.css('Document Folder Placemark').collect do |placemark|
        MapRule.new(
          name: placemark.css('name').text, 
          price: nil,
          deadline: nil,
          coordinates: placemark.css('Polygon coordinates').text
        )
      end
    rescue RestClient::ResourceNotFound => e
      flash.now[:error] = "Mapa não encontrado para MID: #{params[:shipping_method][:mid]}"
    end

  end

  private

  def shipping_method_params
    params.require(:shipping_method).permit(:mid)
  end
end