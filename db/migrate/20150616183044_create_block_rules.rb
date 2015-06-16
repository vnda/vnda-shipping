class CreateBlockRules < ActiveRecord::Migration
  def change
    create_table :block_rules do |t|
      t.integer :shipping_method_id, null: false
      t.index :shipping_method_id
      t.foreign_key :shipping_methods

      t.int4range :range, null: false
    end
  end
end
