class RemoveUniqueConstraintFromShippingMethodsSlug < ActiveRecord::Migration
  def change
    remove_index :shipping_methods, [:shop_id, :slug]
  end
end
