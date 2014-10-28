class AddShopIdToPeriod < ActiveRecord::Migration
  def change
    add_column :periods, :shop_id, :integer
  end
end
