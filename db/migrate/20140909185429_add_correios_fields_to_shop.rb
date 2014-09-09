class AddCorreiosFieldsToShop < ActiveRecord::Migration
  def change
    change_table :shops do |t|
      t.string :correios_code
      t.string :correios_password
      t.boolean :forward_to_correios, null: false, default: false
      t.integer :correios_services, array: true, null: false, default: []
    end
  end
end
