class AddAxadoTokenToShops < ActiveRecord::Migration
  def change
    add_column :shops, :axado_token, :string, limit: 32
  end
end
