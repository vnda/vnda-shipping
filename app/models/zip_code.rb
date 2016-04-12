class ZipCode

  GMAPS_GEOCODING_API_URL = 'https://maps.googleapis.com/maps/api/geocode/json'

  def self.get_geolocation_for(zip_code)
    response = RestClient.get GMAPS_GEOCODING_API_URL, {params: {address: zip_code, region: 'br', key: ENV['GMAPS_GEOCODING_API_KEY']}}
    response = JSON.parse(response).with_indifferent_access
    response[:status].eql?('ZERO_RESULTS') ? {lng: 0, lat: 0} : response[:results].first[:geometry][:location]   
  end

end