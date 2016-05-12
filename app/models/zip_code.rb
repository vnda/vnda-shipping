class ZipCode

  GMAPS_GEOCODING_API_URL = 'https://maps.googleapis.com/maps/api/geocode/json'

  def self.get_geolocation_for(zip_code)
    response = RestClient.get( GMAPS_GEOCODING_API_URL, {params: {address: zip_code, region: 'br', key: ENV['GMAPS_GEOCODING_API_KEY']}} )
    response = JSON.parse(response).with_indifferent_access
    if response[:status].eql?('ZERO_RESULTS')
      puts "Google Maps API response: [ZERO_RESULTS] #{response}"
      {lng: 0, lat: 0}
    else
      results = response[:results] if response
      first_result = results.first if results
      geometry = first_result[:geometry] if first_result
      return geometry[:location] if geometry
      puts "Google Maps API response: #{response}"
      {lng: 0, lat: 0}
    end
  end
end
