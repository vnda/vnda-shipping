require 'test_helper'

describe ZipCode do

  describe '.get_geolocation_for(zip_code)' do
    it "retrives the latitude and longitude for a given zip code" do
      ZipCode.get_geolocation_for('88034100').must_equal '{"lat"=>-27.5759124, "lng"=>-48.5082472}'
    end
  end

end