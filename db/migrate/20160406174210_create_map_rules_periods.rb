class CreateMapRulesPeriods < ActiveRecord::Migration
  def change
    create_table :map_rules_periods do |t|
      t.integer :period_id
      t.integer :map_rule_id

      t.timestamps
    end
  end
end
