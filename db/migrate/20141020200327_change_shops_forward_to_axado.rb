class ChangeShopsForwardToAxado < ActiveRecord::Migration
  def change
    change_column :shops, :forward_to_axado, :boolean, default: false
  end
end
