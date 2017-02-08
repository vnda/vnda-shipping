require 'test_helper'

class ApiSpec < ActionDispatch::IntegrationTest
  setup do
    @shop = shops(:one)
  end

  describe "delivery_dates" do
    it "find shop by host if token is missing" do
      post "/delivery_date", {}, { "HTTP_X_STORE" => "shop" }

      response.status.must_equal 200
    end

    it "returns available zip periods " do
      shipping_method = shipping_methods(:one)
      zip_rule = shipping_method.zip_rules.create!(range: 0..55555555, price: 15.0, deadline: 2)
      zip_rule.periods << periods(:one)

      stub_request(:get, "https://maps.googleapis.com/maps/api/geocode/json?components=postal_code:12946636&key&region=br").
        to_return(status: 200,
          body: Rails.root.join("test/fixtures/12946636.json").read,
          headers: { "Content-Type" => "application/json" })

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
