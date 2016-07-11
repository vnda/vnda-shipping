class CreateZipCodeLocations < ActiveRecord::Migration
  def change
    enable_extension "hstore"

    create_table :zip_code_locations do |t|
      t.string :zip_code, null: false
      t.hstore :location, null: false, default: ''
      t.timestamps
    end
  end
end
