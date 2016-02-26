require 'httparty'
require 'pp'

class Intelipost::ShipmentOrderApi
  include HTTParty
  format :json

  def initialize(shop)
    @base_uri = "api.intelipost.com.br"
    @shop = shop
    @token = shop.intelipost_token
    @headers = { "Content-Type"=> "application/json", "Accept"=> "*/*", "api-key"=> @token }
  end

  def shipment_order(id)
    get("https://#{@base_uri}/api/v1/shipment_order/#{id}")
  end

  def create(params)
    post("https://#{@base_uri}/api/v1/shipment_order", mount_intelipost_order(params))
  end

  def ready_for_shipment(params)
    post("https://#{@base_uri}/api/v1/shipment_order/multi/shipped/with_date", [params])
  end

  def mount_intelipost_order(json)
    params = {}
    params[:quote_id] = json["extra"]["cotation_id"] if json["extra"]
    params[:order_number] = json["code"]
    params[:delivery_method_id] = "2"
    params[:customer_shipping_costs] = json["shipping_price"]
    params[:end_customer] = {}
    params[:end_customer][:first_name] = json["first_name"]
    params[:end_customer][:last_name] = json["last_name"]
    params[:end_customer][:email] = json["email"]
    params[:end_customer][:phone] = "#{json['phone_area']} #{json['phone']}".squish
    params[:end_customer][:is_company] = false
    params[:end_customer][:shipping_address] = json["shipping_address"]["street_name"]
    params[:end_customer][:shipping_number] = json["shipping_address"]["street_number"]
    params[:end_customer][:shipping_additional] = json["shipping_address"]["complement"]
    params[:end_customer][:shipping_quarter] = json["shipping_address"]["neighborhood"]
    params[:end_customer][:shipping_city] = json["shipping_address"]["city"]
    params[:end_customer][:shipping_state] = json["shipping_address"]["state"]
    params[:end_customer][:shipping_zip_code] = json["shipping_address"]["zip"]
    params[:end_customer][:shipping_country] = "BR"
    params[:shipment_order_volume_array] = []

    json["items"].each do |i|
      item = {}
      item[:shipment_order_volume_number] = i["sku"]
      item[:name] = i["product_name"]
      item[:weight] = i["weight"]
      item[:volume_type_code] = "box"
      item[:width] = i["width"]
      item[:height] = i["height"]
      item[:length] = i["length"]
      item[:products_quantity] = i["quantity"]
      item[:products_nature] = "household appliance"
      item[:is_icms_exempt] = false
      item[:tracking_code] = json["tracking_code"]
      params[:shipment_order_volume_array] << item
    end
    JSON.parse(params.to_json)
  end

  def get(url)
    response = self.class.get(url, {headers: @headers})
    JSON.parse(response.body)
  end

  def post(url, params)
    JSON.parse(self.class.post(url, :body => params.to_json, :headers => @headers).body)
  end

  def put(url, params)
    self.class.put(url, :body => params.to_json, :headers => @headers).body
  end
end
