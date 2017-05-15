class AddOriginalShopIdToQuotations < ActiveRecord::Migration
  def change
    add_column :quotations, :original_shop_id, :integer
  end
end
