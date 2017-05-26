class AddCorreiosReceiveAlertToShops < ActiveRecord::Migration
  def change
    add_column :shops, :correios_receive_alert, :boolean, default: false
  end
end
