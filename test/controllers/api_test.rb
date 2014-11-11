require 'test_helper'

class ApiSpec < ActionDispatch::IntegrationTest

  setup do
   @shop = shops(:one)
   @axado_shop = shops(:axado)
   @correios_shop = shops(:correios)
   @shipping_method = shipping_methods(:one)
   @zip_rule = @shipping_method.zip_rules.create!([
         { range: 0..99999999, price: 15.0, deadline: 2 }
       ])
   @period = periods(:one)
   ZipRule.first.periods << @period

  end

  describe "api quote" do
    it "returns available methods" do

      params = JSON.parse('{"origin_zip":"12946636","shipping_zip":"92200290","order_total_price":10.0,"aditional_deadline":null,"aditional_price":null,"products":[{"sku":"CSMT-1","price":10.0,"height":2,"length":16,"width":11,"weight":10}]}')
      post "/quote?token=#{@shop.token}", params

      response.status.must_equal 200
      response.body.must_equal '[{"name":"Metodo 1","price":15.0,"deadline":2,"express":true,"slug":"metodo-1","delivery_type":"Tipo de envio 1"}]'
    end

    it "returns nothing when params is not ok" do
      params = JSON.parse('{"origin_zip":"12946636"}')
      post "/quote?token=#{@shop.token}", params

      response.status.must_equal 400
    end

  end

  describe "axado quote" do
    body = '{"origin_zip":"90540140","shipping_zip":"58135000","order_total_price":10.0,"aditional_deadline":null,"aditional_price":null,"products":[{"sku":"CSMT-1","price":10.0,"height":2,"length":16,"width":11,"weight":0.001}]}'

    it "returns axado quotation" do
      @axado_shop.stubs(:quote)
        .with(body: body)
        .returns('[{"name":"Sedex","price":15.0,"deadline":3,"express":true,"slug":"sedex"}]')

      @axado_shop.quote(body: body).must_equal '[{"name":"Sedex","price":15.0,"deadline":3,"express":true,"slug":"sedex"}]'
    end
  end

  describe "correios quote" do

    it "returns correios quotation" do
      @correios_shop.stubs(:quote)
        .with(body: body)
        .returns('[{"name":"Pac","price":15.0,"deadline":6,"express":false,"slug":"pac"}]')

      @correios_shop.quote(body: body).must_equal '[{"name":"Pac","price":15.0,"deadline":6,"express":false,"slug":"pac"}]'
    end
  end


  describe "delivery_dates" do

    it "unauthorized if token is missing" do
      post "/delivery_date?"

      response.status.must_equal 401
    end

    it "returns available zip periods " do
      post "/delivery_date?token=#{@shop.token}&zip=12946636"

      response.status.must_equal 200
      response.body.must_equal "[\"Manha\"]"
    end

    it "returns next delivery date" do
      post "/delivery_date?token=#{@shop.token}&zip=12946636&period=Manha"

      day = @shop.check_period_rules("Manha")
      parsed_date = {'day' => day[:day], 'year' => day[:year], 'month' => day[:month]}

      response.status.must_equal 200
      ActiveSupport::JSON.decode(response.body).must_equal parsed_date
    end

  end

  describe "delivery_types" do
    it "returns available delivery types" do
      post "/delivery_types?token=#{@shop.token}"

      response.status.must_equal 200
      response.body.must_equal "[\"Tipo de envio 1\"]"
    end

  end

end
