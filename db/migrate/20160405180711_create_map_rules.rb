class CreateMapRules < ActiveRecord::Migration
  def change
    create_table :map_rules do |t|
      t.integer :shipping_method_id, null: false
      t.index :shipping_method_id
      t.foreign_key :shipping_methods

      t.decimal :price, precision: 10, scale: 2
      t.integer :deadline, null: false

      t.text :coordinates, null: false
      t.string :name, null: false
    end
  end
end
