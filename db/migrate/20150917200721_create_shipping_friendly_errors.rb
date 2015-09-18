class CreateShippingFriendlyErrors < ActiveRecord::Migration
  def change
    create_table :shipping_friendly_errors do |t|
      t.string :message
      t.string :rule
      t.references :shop, index: true

      t.timestamps
    end
  end
end
