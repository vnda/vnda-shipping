class AddCorreiosCustomServicesToShops < ActiveRecord::Migration
  def change
    add_column :shops, :correios_custom_services, :string
  end
end
