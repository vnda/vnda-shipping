class AddServiceToShippingMethods < ActiveRecord::Migration
  def change
    add_column :shipping_methods, :service, :string
  end
end
