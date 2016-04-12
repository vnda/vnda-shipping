class ZipCode

  def self.get_geolocation_for(zip_code)
    response = RestClient.get 'http://maps.googleapis.com/maps/api/geocode/json', {params: {address: zip_code, region: 'br'}}
    response = JSON.parse(response).with_indifferent_access
    response[:status].eql?('ZERO_RESULTS') ? {lng: 0, lat: 0} : response[:results].first[:geometry][:location]   
  end

end