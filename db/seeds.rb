puts "Add track ceps"
tracks = File.read(Rails.root.join('db', 'seeds', 'track_ceps_data.json'))
ActiveRecord::Base.transaction do
  JSON.parse(tracks).each do |json|
    TrackCep.create!(json.with_indifferent_access)
  end
end

puts "Add weight tracks"
tracks = File.read(Rails.root.join('db', 'seeds', 'track_weight_data.json'))
ActiveRecord::Base.transaction do
  JSON.parse(tracks).each do |json|
    TrackWeight.create!(json.with_indifferent_access)
  end
end

puts "Done"
