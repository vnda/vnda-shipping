class AddDeliveryTypeIdToShippingMethod < ActiveRecord::Migration
  def change
    add_column :shipping_methods, :delivery_type_id, :integer
  end
end
