class AddTntServiceIdToShops < ActiveRecord::Migration
  def change
    add_column :shops, :tnt_service_id, :integer
  end
end
