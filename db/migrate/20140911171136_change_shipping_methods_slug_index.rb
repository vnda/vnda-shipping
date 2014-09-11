class ChangeShippingMethodsSlugIndex < ActiveRecord::Migration
  def up
    remove_index :shipping_methods, :slug
    add_index :shipping_methods, [:shop_id, :slug], unique: true
  end

  def down
    add_index :shipping_methods, :slug, unique: true
    remove_index :shipping_methods, [:shop_id, :slug]
  end
end
