class CreateShippingMethods < ActiveRecord::Migration
  def change
    create_table :shipping_methods do |t|
      t.integer :shop_id, null: false
      t.index :shop_id
      t.foreign_key :shops

      t.string :name, null: false
      t.string :description, null: false, default: ''
    end
  end
end
