class AddWeigthRangeToShippingMethods < ActiveRecord::Migration
  def change
    add_column :shipping_methods, :weigth_range, :numrange, null: false, default: (nil..nil)
  end
end
