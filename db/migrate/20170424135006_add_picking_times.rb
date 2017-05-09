class AddPickingTimes < ActiveRecord::Migration
  def change
    create_table :picking_times do |t|
      t.boolean :enabled, null: false, default: true
      t.string :weekday, null: false
      t.string :hour, null: false, default: "18:00"
      t.references :shop
    end

    add_index :picking_times, [:enabled, :weekday]
  end
end
