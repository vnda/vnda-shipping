class AddSlugAndExpressToShippingMethods < ActiveRecord::Migration
  def change
    change_table :shipping_methods do |t|
      t.string :slug
      t.boolean :express, default: false, null: false
      t.index :slug, unique: true
    end

    unless reverting?
      ShippingMethod.all.each do |m|
        m.generate_slug
        m.save
      end
    end

    change_column_null(:shipping_methods, :slug, false)
  end
end
