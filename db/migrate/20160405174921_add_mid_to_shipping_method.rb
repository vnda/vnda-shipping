class AddMidToShippingMethod < ActiveRecord::Migration
  def change
    add_column :shipping_methods, :mid, :string
  end
end
