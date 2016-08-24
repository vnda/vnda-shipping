class CreateTrackWeights < ActiveRecord::Migration
  def change
    create_table :track_weights do |t|
      t.string :service_name, index: true
      t.integer :service_code, null: false, index: true
      t.text :tracks, array: true, default: []
    end
  end
end
