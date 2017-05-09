class ChangeShippingMethodsDaysOffToArray < ActiveRecord::Migration
  def change
    remove_column :shipping_methods, :days_off
    add_column :shipping_methods, :days_off, :integer, array: true, null: false, default: []
  end
end
