class TrackCep < ActiveRecord::Base
  # t.string :service_name, null: false, index: true
  # t.integer :service_code, null: false, index: true
  # t.string :state, null: false
  # t.string :type, null: false
  # t.string :name, null: false
  # t.text :tracks, array: true, default: []

  scope :for_service_code, -> service_code { where(service_code: service_code) }
  scope :for_service_name, -> service_name { where(service_name: service_name) }
  scope :for_state, -> state { where(state: state) }
  scope :for_city, -> city { where(name: city) }

  def specified_track
    tracks[2]
  end
end
