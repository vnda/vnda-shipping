class CreateShops < ActiveRecord::Migration
  def change
    create_table :shops do |t|
      t.string :name, null: false
      t.string :token, null: false, limit: 32
      t.index :name, unique: true
      t.index :token, unique: true
    end
  end
end
