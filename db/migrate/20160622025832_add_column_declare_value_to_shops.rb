class AddColumnDeclareValueToShops < ActiveRecord::Migration
  def change
    add_column :shops, :declare_value, :boolean, default: true
  end
end
