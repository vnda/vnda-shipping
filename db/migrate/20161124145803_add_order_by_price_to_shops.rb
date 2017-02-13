class AddOrderByPriceToShops < ActiveRecord::Migration
  def change
    unless column_exists? :shops, :order_by_price
      add_column :shops, :order_by_price, :boolean, default: true
    end
  end
end
