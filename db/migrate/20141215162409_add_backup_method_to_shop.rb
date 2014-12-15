class AddBackupMethodToShop < ActiveRecord::Migration
  def change
    add_column :shops, :backup_method_id, :integer
  end
end
