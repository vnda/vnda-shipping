class CreateZipcodeSpreadsheets < ActiveRecord::Migration
  def change
    create_table :zipcode_spreadsheets do |t|
      t.references :shop, null: false, index: true
      t.references :delivery_type, null: false, index: true
      t.string :service_name, index: true
      t.integer :service_code, index: true
      t.string :zipcode_start, limit: 8, index: true
      t.string :zipcode_end, limit: 8, index: true
      t.float :weight_start
      t.float :weight_end
      t.decimal :absolute_money_cost, precision: 8, scale: 2
      t.decimal :price_percent, precision: 8, scale: 2
      t.decimal :price_by_extra_weight, precision: 8, scale: 2
      t.integer :max_volume, default: 0
      t.integer :time_cost
      t.string :country, limit: 3
      t.decimal :minimum_value_insurance, precision: 8, scale: 2
    end
  end
end
