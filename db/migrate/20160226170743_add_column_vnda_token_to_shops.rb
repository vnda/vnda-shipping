class AddColumnVndaTokenToShops < ActiveRecord::Migration
  def change
    add_column :shops, :vnda_token, :string
  end
end
