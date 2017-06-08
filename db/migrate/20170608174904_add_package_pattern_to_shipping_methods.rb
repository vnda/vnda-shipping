class AddPackagePatternToShippingMethods < ActiveRecord::Migration
  def change
    add_column :shipping_methods, :package_pattern, :string
  end
end
