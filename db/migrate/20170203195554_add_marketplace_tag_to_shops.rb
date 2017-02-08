class AddMarketplaceTagToShops < ActiveRecord::Migration
  def change
    add_column :shops, :marketplace_tag, :string
  end
end
