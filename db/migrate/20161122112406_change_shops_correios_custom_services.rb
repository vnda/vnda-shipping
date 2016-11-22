class ChangeShopsCorreiosCustomServices < ActiveRecord::Migration
  
  def change
    change_column :shops, :correios_custom_services, :text
  end

end
