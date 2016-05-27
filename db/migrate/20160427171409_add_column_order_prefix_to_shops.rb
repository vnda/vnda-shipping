class AddColumnOrderPrefixToShops < ActiveRecord::Migration
  def change
    add_column :shops, :order_prefix, :string, default: ''
  end
end
