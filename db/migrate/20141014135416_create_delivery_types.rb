class CreateDeliveryTypes < ActiveRecord::Migration
  def change
    create_table :delivery_types do |t|
      t.string :name
      t.boolean :enabled

      t.timestamps
    end
  end
end
