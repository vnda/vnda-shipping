class AddRegionToMapRules < ActiveRecord::Migration
  def change
    change_table :map_rules do |t|
      t.st_polygon :region
    end
  end
end
