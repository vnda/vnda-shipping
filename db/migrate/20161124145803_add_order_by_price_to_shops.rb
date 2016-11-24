class AddOrderByPriceToShops < ActiveRecord::Migration
  def change
    add_column :shops, :order_by_price, :boolean, default: true
  end
end
