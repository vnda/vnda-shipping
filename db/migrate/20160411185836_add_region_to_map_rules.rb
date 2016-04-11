class AddRegionToMapRules < ActiveRecord::Migration
  def change
    change_table :map_rules do |t|
      t.polygon :region
    end
  end
end
