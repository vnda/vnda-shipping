class AddRangeToPlace < ActiveRecord::Migration
  def change
    add_column :places, :range, :int4range
  end
end
