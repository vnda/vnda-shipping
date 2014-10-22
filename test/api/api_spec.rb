require 'test_helper'

class ApiSpec < ActionDispatch::IntegrationTest

  setup do
   @shop = shops(:one)
   @shipping_method = shipping_methods(:one)
   @shipping_method.min_weigth = 10
   @shipping_method.max_weigth = 100
   @shipping_method.save
  end

  let(:zip_rule_params) { { shipping_method: @shipping_method, price: 10.00, deadline: 2, range: Range.new(10,100) } }
  let(:zip_rule) { ZipRule.create zip_rule_params }

  describe "items that are viewable by this user" do

    it "returns available methods" do

      params = JSON.parse('{"origin_zip":"90540140","shipping_zip":"92200290","order_total_price":10.0,"aditional_deadline":null,"aditional_price":null,"products":[{"sku":"CSMT-1","price":10.0,"height":2,"length":16,"width":11,"weight":0.001}]}')
      post "/quote?token=#{@shop.token}", params


    end

  end



end
