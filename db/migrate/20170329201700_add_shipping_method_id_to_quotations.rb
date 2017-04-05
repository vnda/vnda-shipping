class AddShippingMethodIdToQuotations < ActiveRecord::Migration
  def change
    add_column :quotations, :shipping_method_id, :integer
    add_index :quotations, :shipping_method_id
  end
end
