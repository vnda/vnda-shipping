class CreatePlaces < ActiveRecord::Migration
  def change
    create_table :places do |t|
      t.integer :shipping_method_id, null: false
      t.index :shipping_method_id
      t.foreign_key :shipping_methods

      t.string :name, null: false

      t.timestamps
    end
  end
end
