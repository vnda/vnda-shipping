require 'test_helper'

describe ZipCodeLocation do
  describe '.get_geolocation_for(zip_code)' do
    it "retrieves the latitude and longitude for a given zip code" do
      stub_request(:get, "https://maps.googleapis.com/maps/api/geocode/json?components=postal_code:88034100&key&region=br").
        to_return(status: 200,
          body: Rails.root.join("test/fixtures/88034100.json").read,
          headers: { "Content-Type" => "application/json" })

      point = ZipCodeLocation.get_geolocation_for("88034100")
      point[:lat].must_equal "-27.5759124"
      point[:lng].must_equal "-48.5082472"
    end
  end
end
