class ZipCodeLocation < ActiveRecord::Base

  GMAPS_GEOCODING_API_URL = 'https://maps.googleapis.com/maps/api/geocode/json'

  validates_presence_of :zip_code, :location

  store_accessor :location

  def self.get_geolocation_for(zip_code)
    zip_code_location = ZipCodeLocation.find_by_zip_code(normalize_zip_code(zip_code)) ||
                        ZipCodeLocation.try_to_create_new_location(zip_code)

    zip_code_location ?
      zip_code_location.location.with_indifferent_access :
      {lng: 0, lat: 0}
  end

  def self.try_to_create_new_location(zip_code)
    response = RestClient.get( GMAPS_GEOCODING_API_URL, {params: {address: zip_code, region: 'br', key: ENV['GMAPS_GEOCODING_API_KEY']}} )
    response = JSON.parse(response).with_indifferent_access

    if response[:status].eql?('ZERO_RESULTS')
      puts "Google Maps API response: [ZERO_RESULTS] #{response}"
      nil
    else
      results = response[:results] if response
      result_for_zipcode = select_result_for_zip(results, zip_code) if results
      geometry = result_for_zipcode[:geometry] if result_for_zipcode

      if geometry
        zip_code_location = ZipCodeLocation.new(zip_code: normalize_zip_code(zip_code))
        zip_code_location.location = geometry[:location]
        zip_code_location.save

        return zip_code_location
      end
      nil
    end
  end

  def self.select_result_for_zip(results, zip)
    results.find do |result|
      result['types'].include?('postal_code') &&
      !result['types'].include?('postal_code_prefix')
    end || results.first
  end

  def self.normalize_zip_code(zip_code)
    zip_code.to_s.sub('-', '')
  end
end
