class AddNoticeToShippingMethods < ActiveRecord::Migration
  def change
    add_column :shipping_methods, :notice, :text
  end
end
