include ConsoleSay

say_with_time "Add track ceps" do
  tracks = File.read(Rails.root.join('db', 'seeds', 'track_ceps_data.json'))

  ActiveRecord::Base.transaction do
    JSON.parse(tracks).each do |json|
      TrackCep.create! json.with_indifferent_access
    end
  end
end

say_with_time "Add weight tracks" do
  tracks = File.read(Rails.root.join('db', 'seeds', 'track_weight_data.json'))

  ActiveRecord::Base.transaction do
    JSON.parse(tracks).each do |json|
      TrackWeight.create! json.with_indifferent_access
    end
  end
end
