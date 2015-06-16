class AddDataOriginToShippingMethods < ActiveRecord::Migration
  def change
    add_column :shipping_methods, :data_origin, :string, null: false, default: "local"
  end
end
