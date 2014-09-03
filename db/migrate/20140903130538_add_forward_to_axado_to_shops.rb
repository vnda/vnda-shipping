class AddForwardToAxadoToShops < ActiveRecord::Migration
  def change
    add_column :shops, :forward_to_axado, :boolean, null: false, default: true
  end
end
