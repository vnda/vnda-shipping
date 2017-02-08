class AddMarketplaceIdToShops < ActiveRecord::Migration
  def change
    add_column :shops, :marketplace_id, :integer, null: false, default: 0
    add_index :shops, :marketplace_id
  end
end
