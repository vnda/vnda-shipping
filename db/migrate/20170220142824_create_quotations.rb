class CreateQuotations < ActiveRecord::Migration
  def change
    create_table :quotations do |t|
      t.belongs_to :shop, null: false
      t.integer :cart_id, null: false
      t.string :package, null: false
      t.string :name, null: false
      t.decimal :price, precision: 10, scale: 2, null: false, default: 0
      t.integer :deadline, null: false, default: 0
      t.string :slug, null: false
      t.string :delivery_type
      t.string :delivery_type_slug
      t.string :deliver_company
      t.text :notice
      t.string :quotation_id
      t.timestamps null: false
    end

    add_index :quotations, :shop_id
    add_index :quotations, :cart_id
  end
end
