class CreateZipRules < ActiveRecord::Migration
  def change
    create_table :zip_rules do |t|
      t.integer :shipping_method_id, null: false
      t.index :shipping_method_id
      t.foreign_key :shipping_methods

      t.int4range :range, null: false
      t.decimal :price, precision: 10, scale: 2
      t.integer :deadline, null: false
    end
  end
end
