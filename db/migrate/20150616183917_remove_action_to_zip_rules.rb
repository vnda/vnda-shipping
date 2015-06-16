class RemoveActionToZipRules < ActiveRecord::Migration
  def change
    remove_column :zip_rules, :action
  end
end
