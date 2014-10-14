class AddShopIdToDeliveryTypes < ActiveRecord::Migration
  def change
    add_column :delivery_types, :shop_id, :integer
  end
end
