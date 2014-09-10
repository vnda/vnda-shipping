class AddNameOptionsToShops < ActiveRecord::Migration
  def change
    add_column :shops, :normal_shipping_name, :string
    add_column :shops, :express_shipping_name, :string
  end
end
