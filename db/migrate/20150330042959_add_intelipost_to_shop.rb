class AddIntelipostToShop < ActiveRecord::Migration
  def change
    change_table :shops do |t|
      t.string :intelipost_token
      t.boolean :forward_to_intelipost, null: false, default: false
    end
  end
end
