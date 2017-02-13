class ShippingMethodForMigration < ActiveRecord::Base
  self.table_name = "shipping_methods"
end

class AddSlugAndExpressToShippingMethods < ActiveRecord::Migration
  def change
    change_table :shipping_methods do |t|
      t.string :slug
      t.boolean :express, default: false, null: false
      t.index :slug, unique: true
    end

    ShippingMethodForMigration.find_each do |m|
      m.update(slug: m.name.try(:parameterize))
    end unless reverting?

    change_column_null(:shipping_methods, :slug, false)
  end
end
