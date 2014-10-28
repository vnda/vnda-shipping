class CreatePeriods < ActiveRecord::Migration
  def change
    create_table :periods do |t|
      t.string :name
      t.time :limit_time
      t.text :days_off

      t.timestamps
    end
  end
end
