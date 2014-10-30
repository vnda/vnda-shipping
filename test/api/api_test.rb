require 'test_helper'

class ApiSpec < ActionDispatch::IntegrationTest

  setup do
   @shop = shops(:one)
   @axado_shop = shops(:axado)
   @correios_shop = shops(:correios)
   @shipping_method = shipping_methods(:one)
   @shipping_method.zip_rules.create!([
         { range: 0..99999999, price: 15.0, deadline: 2 }
       ])
  end

  describe "api quote" do
    it "returns available methods" do

      params = JSON.parse('{"origin_zip":"12946636","shipping_zip":"92200290","order_total_price":10.0,"aditional_deadline":null,"aditional_price":null,"products":[{"sku":"CSMT-1","price":10.0,"height":2,"length":16,"width":11,"weight":10}]}')
      post "/quote?token=#{@shop.token}", params

      response.status.must_equal 200
      response.body.must_equal '[{"name":"Metodo 1","price":15.0,"deadline":2,"express":true,"slug":"metodo-1"}]'
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

    it "returns available zip periods "

  end

  end
end
