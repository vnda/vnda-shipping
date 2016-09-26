class TrackWeight < ActiveRecord::Base
  serialize :tracks, Array

  def medium
    array = []
    tracks.each do |i, v|
      array << (i.to_f + v.to_f).round(2)
    end
    array
  end
end
