require 'test_helper'

class ApiSpec < ActionDispatch::IntegrationTest

  setup do
   @shop = shops(:one)
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



end
