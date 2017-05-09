class AddTntToShops < ActiveRecord::Migration
  def change
    add_column :shops, :forward_to_tnt, :boolean, null: false, default: false
    add_column :shops, :tnt_email, :string
    add_column :shops, :tnt_delivery_type, :string
    add_column :shops, :tnt_cnpj, :string
    add_column :shops, :tnt_ie, :string
  end
end
