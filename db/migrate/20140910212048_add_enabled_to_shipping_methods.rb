class AddEnabledToShippingMethods < ActiveRecord::Migration
  def change
    add_column :shipping_methods, :enabled, :boolean, null: false, default: false
    execute 'UPDATE shipping_methods SET enabled = TRUE' unless reverting?
  end
end
