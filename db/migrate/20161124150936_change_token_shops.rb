class ChangeTokenShops < ActiveRecord::Migration
  def change
    change_column :shops, :token, :string, :limit => 255
  end
end
