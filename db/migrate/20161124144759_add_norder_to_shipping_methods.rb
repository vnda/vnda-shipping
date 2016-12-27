class AddNorderToShippingMethods < ActiveRecord::Migration
  def change
    unless column_exists? :shipping_methods, :norder
      add_column :shipping_methods, :norder, :integer, default: :null
    end
  end
end
