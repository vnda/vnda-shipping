class AddWeigthRangeToShippingMethods < ActiveRecord::Migration
  def change
    add_column :shipping_methods, :weigth_range, :numrange, null: false, default: 0..1000
  end
end
