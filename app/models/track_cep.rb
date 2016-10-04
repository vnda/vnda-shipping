class TrackCep < ActiveRecord::Base
  scope :for_service_code, -> service_code { where(service_code: service_code) }
  scope :for_service_name, -> service_name { where(service_name: service_name) }
  scope :for_state, -> state { where(state: state) }
  scope :for_city, -> city { where(name: city) }

  def specified_track
    tracks[2]
  end
end
