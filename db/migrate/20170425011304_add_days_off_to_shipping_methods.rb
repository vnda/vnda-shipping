class AddDaysOffToShippingMethods < ActiveRecord::Migration
  def change
    add_column :shipping_methods, :days_off, :text
  end
end
