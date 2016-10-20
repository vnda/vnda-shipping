class CreateTrackCeps < ActiveRecord::Migration
  def change
    create_table :track_ceps do |t|
      t.string :service_name, index: true
      t.integer :service_code, null: false, index: true
      t.string :state, null: false
      t.string :type_city, null: false
      t.string :name, null: false
      t.text :tracks, array: true, default: []
    end
  end
end
