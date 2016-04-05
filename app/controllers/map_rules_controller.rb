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
      
      @polygons = xml_doc.css('Document Folder Placemark').collect do |placemark|
        #name: placemark.css('name').text, coordinates: placemark.css('Polygon coordinates').text
      end

      @map_rules = []      
    rescue RestClient::ResourceNotFound => e
      flash.now[:error] = "Mapa não encontrado para MID: #{params[:shipping_method][:mid]}"
    end

  end

end