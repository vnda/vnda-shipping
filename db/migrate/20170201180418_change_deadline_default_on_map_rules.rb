class ChangeDeadlineDefaultOnMapRules < ActiveRecord::Migration
  def up
    change_column_default :map_rules, :deadline, 0
  end

  def down
    change_column_default :map_rules, :deadline, nil
  end
end
