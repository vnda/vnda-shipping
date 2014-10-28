class CreatePeriodsZipRules < ActiveRecord::Migration
  def change
    create_table :periods_zip_rules do |t|
      t.integer :period_id
      t.integer :zip_rule_id

      t.timestamps
    end
  end
end
