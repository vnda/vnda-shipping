class RemoveCorreiosServicesFromShop < ActiveRecord::Migration
  def change
    remove_column :shops, :correios_services
  end
end
