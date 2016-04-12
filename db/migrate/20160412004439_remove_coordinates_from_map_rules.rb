class RemoveCoordinatesFromMapRules < ActiveRecord::Migration
  def change
    remove_column :map_rules, :coordinates
  end
end
