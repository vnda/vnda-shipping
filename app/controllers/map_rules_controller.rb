require 'rest_client'

class MapRulesController < ApplicationController

  def index
    @shop = Shop.find(params[:shop_id])
    @method = ShippingMethod.find(params[:shipping_method_id])

    @map_rules = @method.map_rules.order('id asc')
  end

  def create
    @shop = Shop.find(params[:shop_id])
    @method = ShippingMethod.find(params[:shipping_method_id])
    @map_rule = @method.map_rules.create(map_rule_params)
    flash.now[:notice] = I18n.t('notices.map_rule.create') if @map_rule.persisted?  
  end

  def update
    @map_rule = MapRule.find(params[:id])
    flash.now[:notice] = I18n.t('notices.map_rule.update') if @map_rule.update_attributes(map_rule_params)
  end

  def destroy
    @map_rule = MapRule.find(params[:id])  
    @map_rule.destroy
    flash.now[:notice] = I18n.t('notices.map_rule.destroy')
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

  def map_rule_params
    params.require(:map_rule).permit(:name, :price, :deadline, :coordinates, period_ids: [])
  end
end