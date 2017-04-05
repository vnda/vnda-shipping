class AddZipToShops < ActiveRecord::Migration
  def change
    add_column :shops, :zip, :string
  end
end
