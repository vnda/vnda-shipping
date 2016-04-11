require 'test_helper'
require 'pry'

class ApiSpec < ActionDispatch::IntegrationTest

  setup do
    @shop = shops(:one)
    @axado_shop = shops(:axado)
    @correios_shop = shops(:correios)
    @shipping_method = shipping_methods(:one)
    @zip_rule = @shipping_method.zip_rules.create!([
         { range: 0..55555555, price: 15.0, deadline: 2 }
       ])
    @period = periods(:one)
    ZipRule.first.periods << @period

    @shipping_method_maps = shipping_methods(:maps)
    @map_rule = @shipping_method_maps.map_rules.create!([
       { name: 'region', price: 15.0, deadline: 2, coordinates: '123213 123' }
     ])
  end


  describe "api quote" do

    it "returns nothing when params is not ok" do
      params = JSON.parse('{"origin_zip":"12946636"}')
      post "/quote?token=#{@shop.token}", params

      response.status.must_equal 400
    end

    it "get the lowers prices" do
      shipping_method_two = shipping_methods(:two)
      zip_rule = shipping_method_two.zip_rules.create!([
            { range: 0..55555555, price: 10.0, deadline: 2 }
          ])

      params = JSON.parse('{"origin_zip":"12946636","shipping_zip":"44444444","order_total_price":10.0,"aditional_deadline":null,"aditional_price":null,"products":[{"sku":"CSMT-1","price":10.0,"height":2,"length":16,"width":11,"weight":10}]}')
      post "/quote?token=#{@shop.token}", params

      response.status.must_equal 200
      response.body.must_equal '[{"cotation_id":"","name":"Metodo 2","price":10.0,"deadline":2,"slug":"metodo-2","delivery_type":"Tipo de envio 1","delivery_type_slug":"tipo-de-envio-1","deliver_company":""}]'
    end

    describe "when shipping method has data_origin=local" do      
      
      it "returns available methods" do
        params = JSON.parse('{"origin_zip":"12946636","shipping_zip":"44444444","order_total_price":10.0,"aditional_deadline":null,"aditional_price":null,"products":[{"sku":"CSMT-1","price":10.0,"height":2,"length":16,"width":11,"weight":10, "quantity":1}]}')
        post "/quote?token=#{@shop.token}", params

        response.status.must_equal 200
        response.body.must_equal '[{"cotation_id":"","name":"Metodo 1","price":15.0,"deadline":2,"slug":"metodo-1","delivery_type":"Tipo de envio 1","delivery_type_slug":"tipo-de-envio-1","deliver_company":""}]'
      end

    end

    describe "when shipping method has data_origin=google_maps" do      

      describe "and there are no regions for the zip code" do
        it "returns nothing" do
          params = JSON.parse('{"origin_zip":"12946636","shipping_zip":"66623123","order_total_price":10.0,"aditional_deadline":null,"aditional_price":null,"products":[{"sku":"CSMT-1","price":10.0,"height":2,"length":16,"width":11,"weight":10, "quantity":1}]}')
          post "/quote?token=#{@shop.token}", params

          response.status.must_equal 400
        end  
      end

      describe "and there are regions for the zip code" do
        it "returns available methods" do
          params = JSON.parse('{"origin_zip":"12946636","shipping_zip":"99999111","order_total_price":10.0,"aditional_deadline":null,"aditional_price":null,"products":[{"sku":"CSMT-1","price":10.0,"height":2,"length":16,"width":11,"weight":10, "quantity":1}]}')
          post "/quote?token=#{@shop.token}", params

          response.status.must_equal 200
          response.body.must_equal '[{"cotation_id":"","name":"Metodo Maps","price":15.0,"deadline":2,"slug":"metodo-maps","delivery_type":"Tipo de envio 1","delivery_type_slug":"tipo-de-envio-1","deliver_company":""}]'
        end
      end
      
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

    it "find shop by host if token is missing" do
      post "/delivery_date?"

      response.status.must_equal 200
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
      response.body.must_equal "[\"Tipo de envio 1\",\"Normal\"]"
    end

  end

end
