class CreateShippingErrors < ActiveRecord::Migration
  def change
    create_table :shipping_errors do |t|
      t.string :message
      t.references :shop, index: true

      t.timestamps
    end
  end
end
